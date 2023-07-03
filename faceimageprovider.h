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
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override
    {
//        qDebug()<<"id is "<<id;
        QImage i(id);
        if (size)
            *size = QSize(i.width(), i.height());


        return i;
    }
};

#endif // FACEIMAGEPROVIDER_H



class ColorImageProvider
{
public:



};
