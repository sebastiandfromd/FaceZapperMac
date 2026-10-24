#ifndef FACEIMAGEPROVIDER_H
#define FACEIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QDebug>

class FaceImageProvider : public QQuickImageProvider
{
public:
    FaceImageProvider()
        : QQuickImageProvider(QQuickImageProvider::ImageType::Image/*,QQmlImageProviderBase::ForceAsynchronousImageLoading*/) {
    }

    // id is the percent-encoded file name inside folder(), e.g. "image://faceProvider/Kaya%2C%20Ela.jpg".
    // The folder stays out of the URL, because Android content URIs (content://.../tree/primary%3ADCIM%2F09B)
    // would not survive being nested inside another URL.
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

    QString folder() const { return m_folder; }
    void setFolder(const QString &folder) { m_folder = folder; }

private:
    QString m_folder;
};

#endif // FACEIMAGEPROVIDER_H
