#
# Be sure to run `pod lib lint BGBadAccessProtect.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BGBadAccessProtect'
  s.version          = '0.1.0'
  s.summary          = '野指针防护'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/jin fu/BGBadAccessProtect'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jin fu' => 'fujin@banggood.com' }
  s.source           = { :git => 'https://github.com/jin fu/BGBadAccessProtect.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.default_subspec = 'All'
  s.subspec 'All' do |spec|
    spec.dependency 'BGBadAccessProtect/Core'
    spec.dependency 'BGBadAccessProtect/ZombieHook'
  end
  
  s.subspec 'Core' do |spec|
    spec.requires_arc = true
    spec.public_header_files = "BGBadAccessProtect/Classes/Core/BGBadAccessProtect.h"
    spec.source_files  = "BGBadAccessProtect/Classes/Core/*.{h,m}"
  end
  
  s.subspec 'ZombieHook' do |spec|
    spec.requires_arc = false
    spec.source_files  = "BGBadAccessProtect/Classes/ZombieHook/*.{h,m}"
    spec.dependency 'BGBadAccessProtect/Core'
  end
  
end
