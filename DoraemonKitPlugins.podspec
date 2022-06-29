#
# Be sure to run `pod lib lint DoraemonKitPlugins.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DoraemonKitPlugins'
  s.version          = '0.1.0'
  s.summary          = 'Plugins For DoraemonKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

#   s.description      = <<-DESC
# TODO: Add long description of the pod here.
#                        DESC

  s.homepage         = 'https://github.com/sevensea996/DoraemonKitPlugins'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'sevensea996' => 'weihaideng@126.com' }
  s.source           = { :git => 'https://github.com/sevensea996/DoraemonKitPlugins.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'DoraemonKitPlugins/Classes/**/*'
  
  # s.resource_bundles = {
  #   'DoraemonKitPlugins' => ['DoraemonKitPlugins/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'DoraemonKit/Core', '3.1.2'
  s.dependency 'MLeaksFinder', '2.0.0'
end
