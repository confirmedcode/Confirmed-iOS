inhibit_all_warnings!
use_frameworks!

platform :ios, '9.0'

target :'Confirmed VPN' do
    pod 'ReachabilitySwift'
    pod 'SwiftMessages'
    pod 'PromiseKit'
    pod 'PromiseKit/Alamofire', '~> 6.0'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'CNPPopupController'
    pod 'LGSideMenuController', '2.1.1'
    pod 'Armchair'
    pod 'RevealingSplashView'
    pod 'Alamofire'
    pod 'SkyFloatingLabelTextField', '~> 3.0'
    pod 'TextFieldEffects'
    pod 'KeychainAccess'
    pod 'Segmentio'
    pod 'NVActivityIndicatorView'
    pod 'CocoaLumberjack'
    pod 'PopupDialog', '~> 0.9'
end


target :'Confirmed Tunnels' do
    pod 'SwiftyUserDefaults'
    pod 'PromiseKit'
    pod 'PromiseKit/Alamofire', '~> 6.0'
    pod 'CocoaLumberjack'
    pod 'KeychainAccess'
    pod 'Alamofire'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'ReachabilitySwift'
    
end

target :'Today' do
    pod 'PromiseKit'
    pod 'PromiseKit/Alamofire', '~> 6.0'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'Alamofire'
    pod 'KeychainAccess'
    pod 'CocoaLumberjack'
    pod 'ReachabilitySwift'
    
end

post_install do |installer| 
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
    end
end
