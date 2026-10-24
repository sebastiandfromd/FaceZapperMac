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

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};

#endif // FACEIMAGEPROVIDER_H

