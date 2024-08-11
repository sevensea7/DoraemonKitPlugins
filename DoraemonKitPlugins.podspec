#
# Be sure to run `pod lib lint DoraemonKitPlugins.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

# pod cache clean --all
# pod spec lint DoraemonKitPlugins.podspec --sources='https://github.com/CocoaPods/Specs.git,https://github.com/sevensea7/Specs.git' --allow-warnings --use-libraries --verbose --skip-import-validation
# pod repo push MySpecs DoraemonKitPlugins.podspec --allow-warnings --use-libraries --skip-import-validation


Pod::Spec.new do |s|
  s.name             = 'DoraemonKitPlugins'
  s.version          = '1.0.0'
  s.summary          = 'Plugins For DoraemonKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

   s.description      = 'Add Custom Plugins For DoraemonKit.'

  s.homepage         = 'https://github.com/sevensea7/DoraemonKitPlugins'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'sevensea7' => 'weihaideng@126.com' }
  s.source           = { :git => 'https://github.com/sevensea7/DoraemonKitPlugins.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.subspec 'Network' do |n|
    s.source_files = 'DoraemonKitPlugins/Classes/Network/**/*'
  end
  
  s.dependency 'DoraemonKit/Core'
  
end
