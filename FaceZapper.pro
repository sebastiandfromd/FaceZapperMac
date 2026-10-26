QT += quick

CONFIG += c++11
android {
    CONFIG += android
    # Google Play: ANDROID_VERSION_CODE must grow with every upload
    ANDROID_VERSION_CODE = 1
    ANDROID_VERSION_NAME = "1.0"
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

RESOURCES += qml.qrc

TRANSLATIONS += \
    FaceZapper_de_DE.ts

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
