inhibit_all_warnings!
use_frameworks!

platform :ios, '11.0'

target :'Confirmed VPN' do
    pod 'ReachabilitySwift'
    pod 'SwiftMessages', '6.0.0'
    pod 'PromiseKit'
    pod 'PromiseKit/Alamofire', '~> 6.0'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'CNPPopupController'
    pod 'LGSideMenuController', '2.1.1'
    pod 'Alamofire'
    pod 'SkyFloatingLabelTextField', '~> 3.0'
    pod 'TextFieldEffects'
    pod 'KeychainAccess', '3.2.0'
    pod 'Segmentio'
    pod 'NVActivityIndicatorView'
    pod 'CocoaLumberjack', '3.4.2'
    pod 'PopupDialog', '~> 0.9'
    pod 'TunnelKit', '1.4.0'
end


target :'Confirmed Tunnels' do
    pod 'SwiftyUserDefaults'
    pod 'PromiseKit'
    pod 'PromiseKit/Alamofire', '~> 6.0'
    pod 'CocoaLumberjack', '3.4.2'
    pod 'KeychainAccess', '3.2.0'
    pod 'Alamofire'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'ReachabilitySwift'
    pod 'TunnelKit', '1.4.0'
end

target :'Today' do
    pod 'PromiseKit'
    pod 'PromiseKit/Alamofire', '~> 6.0'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'Alamofire'
    pod 'KeychainAccess', '3.2.0'
    pod 'CocoaLumberjack', '3.4.2'
    pod 'ReachabilitySwift'
    pod 'TunnelKit', '1.4.0'
end

post_install do |installer| 
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
    end
end
