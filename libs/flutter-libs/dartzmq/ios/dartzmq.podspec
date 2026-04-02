Pod::Spec.new do |s|
  s.name             = 'dartzmq'
  s.version          = '1.0.0-dev.15'
  s.summary          = 'A simple dart zeromq implementation/wrapper around the libzmq C++ library'
  s.description      = <<-DESC
A simple dart zeromq implementation/wrapper around the libzmq C++ library.
                       DESC
  s.homepage         = 'https://github.com/enwi/dartzmq'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'wirmo' => 'contact@wirmo.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '11.0'
  s.swift_version    = '5.0'

  # Exclude i386 and arm64 from iOS Simulator build
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  # If you want to run this app on an iOS real device, uncomment the following line and comment the next one, 
  s.pod_target_xcconfig = { "OTHER_LDFLAGS" => "$(inherited) -force_load $(PODS_TARGET_SRCROOT)/Frameworks/libzmq.a -lstdc++" }
  
  #If you want to run this app on an iOS simulator, uncomment the following line and comment the above one, 
  # s.pod_target_xcconfig = { "OTHER_LDFLAGS" => "$(inherited) -force_load $(PODS_TARGET_SRCROOT)/Frameworks/libzmq_simulator.a -lstdc++" }

  # After you have make the changes, run the following commands:
  # $ cd ios
  # $ pod install
  # $ cd ../macos
  # $ pod install

end