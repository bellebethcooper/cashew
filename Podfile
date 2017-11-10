platform :osx, '10.11'
use_frameworks!

target 'Cashew' do

pod 'FXKeychain', '~> 1.5'
pod 'AFNetworking', '~> 3.0'
pod 'FMDB/FTS'
pod 'Fabric'
pod 'Crashlytics'
pod 'hoedown'
pod 'iRate', '~> 1.11'
# pod 'MASShortcut'
pod 'CocoaLumberjack/Swift'
# pod 'ObjectiveGit'

end

target 'CashewTests' do

end

target 'CashewUITests' do

end



# Workaround for Swift 2.3
post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'CocoaLumberjack'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = 2.3
            end
        end
    end
end
