# BadAccessProtect
对已经释放的对象进行僵尸化，并再次询问时crash防护

## 野指针介绍
**Obj-C对象释放之后指针未置空，导致的野指针。**
现实大概是下面几种可能的情况：
1. 对象释放后内存没被改动过，原来的内存保存完好，可能不Crash或者出现逻辑错误（!!#38761d 随机Crash!!）。
2. 对象释放后内存没被改动过，但是它自己析构的时候已经删掉某些必要的东西，可能不Crash、Crash在访问依赖的对象比如类成员上、出现逻辑错误（!!#38761d 随机Crash!!）。
3. 对象释放后内存被改动过，写上了不可访问的数据，直接就出错了很可能Crash在objc_msgSend上面（!!#38761d 必现Crash!!，常见）。
4. 对象释放后内存被改动过，写上了可以访问的数据，可能不Crash、出现逻辑错误、间接访问到不可访问的数据（!!#38761d 随机Crash!!）。
5. 对象释放后内存被改动过，写上了可以访问的数据，但是再次访问的时候执行的代码把别的数据写坏了，遇到这种Crash只能哭了（!!#38761d 随机Crash!!，难度大，概率低）！！
6. 对象释放后再次release（几乎是!!#38761d 必现Crash!!，但也有例外，很常见）。
![552dlb36dp.png](/tfl/pictures/202206/tapd_30391015_1655086426_4.png)
## 如何防护
**对象即将释放时，将其内存保留延长释放时间。**
主要实现：MRC环境拦截基类(NSObject)dealloc方法，将对象内存保留不进行释放，并将对象变成自定义的类对象（僵尸对象），再进行僵尸对象内存管理。
**dealloc底层实现**
![企业微信20220613-102751.png](/tfl/pictures/202206/tapd_30391015_1655087292_4.png)
NSObject执行 `dealloc` 时调用 `_objc_rootDealloc` 继而调用 `object_dispose` 随后调用 `objc_destructInstance` 方法，前几步都是条件判断和简单的跳转，最后的这个函数如下：
`objc_destructInstance` 方法简单明确的干了三件事：
1. 执行一个叫 `object_cxxDestruct` 的东西干了点什么事（析构函数，释放成员变量等）
2. 执行 `_object_remove_assocations` 去除和这个对象assocate的对象（常用于category中添加带变量的属性）
3. 执行 `objc_clear_deallocating` ，清空引用计数表并清除弱引用表，将所有 `weak` 引用指nil（这也就是weak变量能安全置空的所在）

``` 
void *objc_destructInstance(id obj)
{
    if (obj) {
        Class isa_gen = _object_getClass(obj);
        class_t *isa = newcls(isa_gen);

        // Read all of the flags at once for performance.
        bool cxx = hasCxxStructors(isa);
        bool assoc = !UseGC && _class_instancesHaveAssociatedObjects(isa_gen);

        // This order is important.
        if (cxx) object_cxxDestruct(obj);
        if (assoc) _object_remove_assocations(obj);

        if (!UseGC) objc_clear_deallocating(obj);
    }

    return obj;
}
```

**dealloc 拦截实现**
``` 
- (void)zombie_dealloc
{
    Class currentClass = self.class;
    // 释放掉 关联对象等
    objc_destructInstance(self);
    // 变成僵尸对象 isa指向BGZombieSub类
    object_setClass(self, [BGZombieSub class]);
    BGZombieSub *obj = (BGZombieSub *)self;
    // 将僵尸对象加入一个容器中进行管理
    addZombieObj(_header, (__bridge void *)obj, currentClass);
}
```
## 僵尸对象内存管理策略
1.通过c单链表进行管理。（因为oc的涉及到引用计数，很难进行管理）
2.每30s进行清理僵尸对象。（如果对象释放之后30s之内未被引用到，将其释放）
3.每5s查看一下当前可用内存。（如果内存即将警告，清理当前一半的僵尸对象，这里警告有个阀值：可用内存达到物理内存50%左右）
4.applicationDidReceiveMemoryWarning内存收到警告，同3.
![5e052f7f080ac9284798b7f01f357666.jpg](/tfl/pictures/202206/tapd_30391015_1655089837_24.jpg)
## 防护大致的一个时序图
![企业微信20220608-150710.png](/tfl/pictures/202206/tapd_30391015_1655088798_95.png)

## References
[#dealloc过程及.cxx_destruct的探究](https://blog.sunnyxx.com/2014/04/02/objc_dig_arc_dealloc/) 
[腾讯Bugly野指针三部曲-1](https://cloud.tencent.com/developer/article/1070505)
[腾讯Bugly野指针三部曲-2](https://cloud.tencent.com/developer/article/1070512)
[腾讯Bugly野指针三部曲-3](https://cloud.tencent.com/developer/article/1070528)
[crash 防护](https://mp.weixin.qq.com/s/TW5NMiGKYY3jTNuugbJxfQ)
