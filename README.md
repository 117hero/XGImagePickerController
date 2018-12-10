<p align="center">
  <img src="XGImagePickerController_logo.png" title="XGImagePickerController logo" float=left>
</p>

功能描述
==============
XGImagePickerController是一款iOS相册选择器，支持图片、视频拍摄，多图片、多视频混选及预览， 支持Gif浏览(iOS11+)，多个相册目录同一图片/视频可自动排重，并具有记录已选图片/视频的功能。


系统要求
==============
该项目最低支持 `iOS 8.0+`。

安装
==============

### CocoaPods

1. 在 Podfile 中添加  `pod 'XGImagePickerController'`。
2. 执行 `pod install` 或 `pod update`。
3. 


注意事项
==============
1. 如果运行崩溃,崩溃信息log为：This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSPhotoLibraryUsageDescription/NSCameraUsageDescription key with a string value explaining to the user how the app uses this data.
请检查Info.plist是否添加相册/相机权限: NSPhotoLibraryUsageDescription/NSCameraUsageDescription

2. 模拟器环境下，虽然在工程的Localizations配置中添加了简体中文Chinese（Simplified）,但相册名称仍会默认为英文，这是正常的，因为Localizations在真机环境下才会生效（即真机环境下相册名称会显示成中文）。


许可证
==============
XGImagePickerController 使用 MIT 许可证，详情见 LICENSE 文件。


<br/><br/>
---



Documentation
==============



Requirements
==============
This library requires `iOS 8.0+` .

Notice
==============
If you get crash with message like 'This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSPhotoLibraryUsageDescription/NSCameraUsageDescription key with a string value explaining to the user how the app uses this data.',please check if the corresponding usage description is added in the app's Info.plist.

License
==============
XGImagePickerController is provided under the MIT license. See LICENSE file for details.






 




