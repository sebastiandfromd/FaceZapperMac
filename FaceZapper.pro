QT += quick

CONFIG += c++11

# app version, shown on the "Über FaceZapper" page and used as the Android version name
VERSION = 1.3
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

win32 {
    # icon and "Eigenschaften -> Details" of FaceZapper.exe (icon from tools/make-icons)
    RC_ICONS = windows/FaceZapper.ico
    QMAKE_TARGET_PRODUCT = FaceZapper
    QMAKE_TARGET_DESCRIPTION = "Namen und Gesichter lernen"
    QMAKE_TARGET_COPYRIGHT = "(c) 2026 Sebastian Diel"
}

macx {
    # app bundle (built by .github/workflows/macos.yml; icon from tools/make-icons)
    ICON = mac/FaceZapper.icns
    QMAKE_INFO_PLIST = mac/Info.plist
    QMAKE_TARGET_BUNDLE_PREFIX = de.herrdiel
    QMAKE_BUNDLE = facezapper
}

android {
    CONFIG += android
    # Google Play: ANDROID_VERSION_CODE must grow with every upload
    ANDROID_VERSION_CODE = 4
    ANDROID_VERSION_NAME = $$VERSION
}

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        controller.cpp \
        faceimageprovider.cpp \
        learningsession.cpp \
        lettermodel.cpp \
        folderstore.cpp \
        folderdata.cpp \
        main.cpp \
        namederivationtable.cpp \
        persondata.cpp

RESOURCES += qml.qrc \
    beispiel.qrc \
    licenses.qrc

# UI languages: German is the source (qsTr texts), the .qm files are built into the resources
# as :/i18n/FaceZapper_<code>.qm - update with tools/update-translations.ps1
TRANSLATIONS += \
    i18n/FaceZapper_de.ts \
    i18n/FaceZapper_en.ts \
    i18n/FaceZapper_es.ts \
    i18n/FaceZapper_fr.ts \
    i18n/FaceZapper_it.ts \
    i18n/FaceZapper_nl.ts \
    i18n/FaceZapper_pt_BR.ts
CONFIG += lrelease embed_translations

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    controller.h \
    faceimageprovider.h \
    learningsession.h \
    lettermodel.h \
    folderstore.h \
    folderdata.h \
    namederivationtable.h \
    persondata.h

contains(ANDROID_TARGET_ARCH,arm64-v8a) {
    ANDROID_PACKAGE_SOURCE_DIR = \
        $$PWD/android
}
