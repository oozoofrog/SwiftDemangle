echo "Cleaning..."
rm -rf ./build

echo "Archiving..."
xcodebuild archive -scheme SwiftDemangle-Package -archivePath "./build/ios.xcarchive" -sdk iphoneos SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild archive -scheme SwiftDemangle-Package  -archivePath "./build/ios_sim.xcarchive" -sdk iphonesimulator SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild archive -scheme SwiftDemangle-Package  -archivePath "./build/mac.xcarchive" -sdk macosx11.3 SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "Create XCFramework"
xcodebuild -create-xcframework \
-framework "./build/ios.xcarchive/Products/Library/Frameworks/SwiftDemangle.framework" \
-framework "./build/ios_sim.xcarchive/Products/Library/Frameworks/SwiftDemangle.framework" \
-framework "./build/mac.xcarchive/Products/Library/Frameworks/SwiftDemangle.framework" \
-output "./Binary/SwiftDemangle.xcframework"

echo "Cleaning..."
rm -rf ./build
