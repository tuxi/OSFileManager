#
#  Be sure to run `pod spec lint OSFileManager.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|


  s.name         = "OSFileManager"
  s.version      = "0.0.3"
  s.summary      = "iOS设备上异步文件操作(移动、复制)，同时回调文件进度及状态信息"
  s.description  = "iOS设备上异步文件操作(移动、复制)，同时回调文件进度及状态信息，适用于大文件操作"
  s.platform     = :ios, "8.0"
  s.homepage     = "https://github.com/Ossey/OSFileManager"
  s.license      = "MIT"
  s.author             = { "Ossey" => "xiaoyuan1314@me.com" }
  s.source       = { :git => "https://github.com/Ossey/OSFileManager.git", :tag => "#{s.version}" }
  s.source_files = "OSFileManager/OSFileManager/OSFileManager.{h,m}"
  s.requires_arc = true

end
