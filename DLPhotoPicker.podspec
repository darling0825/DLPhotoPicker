Pod::Spec.new do |s|
  s.name                  = 'DLPhotoPicker'
  s.version               = '1.2.1'
  s.summary               = 'iOS control that allows picking or displaying photos and videos from user\'s photo library.'
  s.description           = <<-DESC
                            DLPhotoPicker is an iOS controller that allows picking
                            or displaying photos and videos from user's photo library.
                            The usage and look-and-feel just similar to UIImagePickerController.
                            It uses **ARC** and **Photos** frameworks.
                            DESC

  s.homepage              = 'https://github.com/darling0825/DLPhotoPicker'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { "darling0825" => "darling0825@163.com" }
  s.platform              = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.source                = { :git => 'https://github.com/darling0825/DLPhotoPicker.git', :tag => s.version }
  s.public_header_files   = 'DLPhotoPicker/**/*.h'
  s.source_files          = 'DLPhotoPicker/**/*.{h,m}'
  s.resource_bundles      = { 'DLPhotoPicker' => ['DLPhotoPicker/Resources/*.xcassets', 'DLPhotoPicker/Resources/Localizations/*.lproj'] }
  s.ios.frameworks        = 'Photos','AssetsLibrary'
  s.requires_arc          = true
  s.dependency            'PureLayout', '~> 3.0.0'
  s.dependency            'SVProgressHUD'
  s.dependency            'TOCropViewController'
end
