echo "Cleaning..."
rm -rf ./build
rm -rf ./Binary
rm -rf ./*.xcframework

echo "Archiving..."
# build framework for iOS
xcodebuild archive \
    -scheme SwiftDemangle \
    -destination "generic/platform=iOS" \
    -archivePath "./build/ios.xcarchive" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# build framework for iOS Simulator
xcodebuild archive \
    -scheme SwiftDemangle \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "./build/ios-simulator.xcarchive" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# build framework for macOS
xcodebuild archive \
    -scheme SwiftDemangle \
    -destination "generic/platform=macOS" \
    -archivePath "./build/macos.xcarchive" \
    -sdk macosx \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "Create XCFramework"
# create XCFramework
xcodebuild -create-xcframework \
    -framework "./build/ios.xcarchive/Products/Library/Frameworks/SwiftDemangle.framework" \
    -framework "./build/ios-simulator.xcarchive/Products/Library/Frameworks/SwiftDemangle.framework" \
    -framework "./build/macos.xcarchive/Products/Library/Frameworks/SwiftDemangle.framework" \
    -output "./SwiftDemangle.xcframework"

echo "Cleaning..."
rm -rf ./build
