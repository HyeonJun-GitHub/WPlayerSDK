# WPlayerSDK
오디오 플레이어

전체OS SDK 동시배포

--XCFramework 생성
on startXCFramework(path, name, type)
    set pathString to path as string
    set nameString to name as string
    set typeString to type as string
    set savePath to "./release"
     
    tell application "Terminal"
         
        #결과물
        set xcarchive to "" as string
        set xcframework to "" as string
         
        #SDK폴더 이동
        set cdCmd to "cd */" & nameString & ";" as string
        set buildCmd to " Xcodebuild -create-xcframework" as string
        set outputCmd to " -output " & savePath & "/" & nameString & ".xcframework" as string
         
        #아카이브
        set iosXcarchive to " Xcodebuild archive -scheme " & nameString & " -archivePath " & savePath & "/iOS.xcarchive -sdk iphoneos SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES;" as string
        set iosSimXcarchive to " Xcodebuild archive -scheme " & nameString & " -archivePath " & savePath & "/iOS_SIM.xcarchive -sdk iphonesimulator SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES;" as string
        set macosXcarchive to " Xcodebuild archive -scheme " & nameString & " -archivePath " & savePath & "/MacOS.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES;" as string
         
        #Framework..
        set iosFramework to " -framework " & savePath & "/iOS.xcarchive/Products/Library/Frameworks/" & nameString & ".framework" as string
        set iosSimFramework to " -framework " & savePath & "/iOS_SIM.xcarchive/Products/Library/Frameworks/" & nameString & ".framework" as string
        set macosFramework to " -framework " & savePath & "/MacOS.xcarchive/Products/Library/Frameworks/" & nameString & ".framework" as string
         
        #OutPut XCFrmaework
        if typeString is "iOS" then
            set xcarchive to iosXcarchive & iosSimXcarchive
            set xcframework to iosFramework & iosSimFramework
             
        else if typeString is "MacOS" then
            set xcarchive to macosXcarchive
            set xcframework to macosFramework
             
        else if typeString is "iOS & MacOS" then
            set xcarchive to iosXcarchive & iosSimXcarchive & macosXcarchive
            set xcframework to iosFramework & iosSimFramework & macosFramework
             
        end if
         
        -- 경로 이동 -- 아카이브 설정 -- 빌드 실행 -- 프렘워크 생성 -- 결과물
        do script cdCmd & xcarchive & buildCmd & xcframework & outputCmd
         
    end tell
end startXCFramework
 
 
--파일열기
tell application "Finder"
    activate
    set filePath to choose folder with prompt "SDK를 선택해주세요."
    set filePath to POSIX path of filePath
    set fileName to name of (info for (POSIX file filePath as alias))
     
    set distributionTypes to {"iOS", "MacOS", "iOS & MacOS"}
    set selectedType to choose from list distributionTypes with prompt "지원하실 플렛폼을 선택해주세요.(Default:iOS)" default items {"iOS"}
    my startXCFramework(filePath, fileName, selectedType)
end tell
