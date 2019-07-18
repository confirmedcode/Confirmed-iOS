inhibit_all_warnings!
use_frameworks!

platform :ios, '11.0'

target :'Confirmed VPN' do
    pod 'ReachabilitySwift', '4.1.0'
    pod 'SwiftMessages', '6.0.0'
    pod 'PromiseKit', '6.7.0'
    pod 'PromiseKit/Alamofire', '6.7.0'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'CNPPopupController'
    pod 'LGSideMenuController', '2.1.1'
    pod 'Alamofire', '4.5.1'
    pod 'SkyFloatingLabelTextField', '~> 3.0'
    pod 'TextFieldEffects'
    pod 'KeychainAccess', '3.1.0'
    pod 'Segmentio'
    pod 'NVActivityIndicatorView', '4.7.0'
    pod 'CocoaLumberjack', '3.4.2'
    pod 'PopupDialog', '~> 0.9'
    pod 'TunnelKit', '1.4.0'
    pod 'OpenSSL-Apple', '1.1.0i.2'
end


target :'Confirmed Tunnels' do
    pod 'SwiftyUserDefaults', '3.0.0'
    pod 'PromiseKit', '6.7.0'
    pod 'PromiseKit/Alamofire', '6.7.0'
    pod 'CocoaLumberjack', '3.4.2'
    pod 'KeychainAccess', '3.1.0'
    pod 'Alamofire', '4.5.1'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'ReachabilitySwift', '4.1.0'
    pod 'TunnelKit', '1.4.0'
    pod 'OpenSSL-Apple', '1.1.0i.2'
end

target :'Today' do
    pod 'PromiseKit', '6.7.0'
    pod 'PromiseKit/Alamofire', '6.7.0'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'Alamofire', '4.5.1'
    pod 'KeychainAccess', '3.1.0'
    pod 'CocoaLumberjack', '3.4.2'
    pod 'ReachabilitySwift', '4.1.0'
    pod 'TunnelKit', '1.4.0'
    pod 'OpenSSL-Apple', '1.1.0i.2'
end

post_install do |installer| 
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
    end
end
