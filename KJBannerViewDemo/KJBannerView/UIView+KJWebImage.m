//
//  UIView+KJWebImage.m
//  KJBannerViewDemo
//
//  Created by 杨科军 on 2021/1/28.
//  Copyright © 2021 杨科军. All rights reserved.
//  https://github.com/yangKJ/KJBannerViewDemo

#import "UIView+KJWebImage.h"
@interface UIView()<KJBannerWebImageHandle>
@end
@implementation UIView (KJWebImage)
- (void)kj_setImageWithURL:(NSURL*)url handle:(void(^)(id<KJBannerWebImageHandle>handle))handle{
    if (url == nil) return;
    self.cacheDatas = true;
    if (handle) handle(self);
    id<KJBannerWebImageHandle> han = (id<KJBannerWebImageHandle>)self;
    if ([self isKindOfClass:[UIImageView class]]) {
        [self kj_setImageViewImageWithURL:url handle:han];
    }else if ([self isKindOfClass:[UIButton class]]) {
        [self kj_setButtonImageWithURL:url handle:han];
    }else if ([self isKindOfClass:[UIView class]]) {
        [self kj_setViewImageContentsWithURL:url handle:han];
    }
}

#pragma mark - UIImageView
- (void)kj_setImageViewImageWithURL:(NSURL*)url handle:(id<KJBannerWebImageHandle>)han{
    __block UIImageView *imageView = (UIImageView*)self;
    __block CGSize size = imageView.frame.size;
    if (han.placeholder) imageView.image = han.placeholder;
    kGCD_banner_async(^{
        NSData *data = [KJBannerViewCacheManager kj_getGIFImageWithKey:url.absoluteString];
        if (data) {
            kGCD_banner_main(^{
                imageView.image = kBannerWebImageSetImage(data, size, han);
            });
        }else{
            kBannerWebImageDownloader(url, size, han, ^(UIImage * _Nonnull image) {
                kGCD_banner_main(^{ imageView.image = image;});
            });
        }
    });
}

#pragma mark - UIButton
- (UIControlState)buttonState{
    return (UIControlState)[objc_getAssociatedObject(self, _cmd) intValue];
}
- (void)setButtonState:(UIControlState)buttonState{
    objc_setAssociatedObject(self, @selector(buttonState), @(buttonState), OBJC_ASSOCIATION_ASSIGN);
}
- (void)kj_setButtonImageWithURL:(NSURL*)url handle:(id<KJBannerWebImageHandle>)han{
    __block UIButton *button = (UIButton*)self;
    __block CGSize size = button.imageView.frame.size;
    if (han.placeholder) [button setImage:han.placeholder forState:han.buttonState];
    kGCD_banner_async(^{
        NSData *data = [KJBannerViewCacheManager kj_getGIFImageWithKey:url.absoluteString];
        if (data) {
            kGCD_banner_main(^{
                [button setImage:kBannerWebImageSetImage(data, size, han) forState:han.buttonState?:UIControlStateNormal];
            });
        }else{
            kBannerWebImageDownloader(url, size, han, ^(UIImage * _Nonnull image) {
                kGCD_banner_main(^{
                    [button setImage:image forState:han.buttonState?:UIControlStateNormal];
                });
            });
        }
    });
}

#pragma mark - UIView
- (CALayerContentsGravity)viewContentsGravity{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setViewContentsGravity:(CALayerContentsGravity)viewContentsGravity{
    objc_setAssociatedObject(self, @selector(viewContentsGravity), viewContentsGravity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)kj_setViewImageContentsWithURL:(NSURL*)url handle:(id<KJBannerWebImageHandle>)han{
    __banner_weakself;
    __block CGSize size = weakself.frame.size;
    kGCD_banner_async(^{
        NSData *data = [KJBannerViewCacheManager kj_getGIFImageWithKey:url.absoluteString];
        if (data) {
            kGCD_banner_main(^{
                UIImage *image = kBannerWebImageSetImage(data, size, han);
                CALayer *layer = [weakself kj_setLayerImageContents:image?:han.placeholder];
                layer.contentsGravity = han.viewContentsGravity?:kCAGravityResize;
            });
        }else{
            kBannerWebImageDownloader(url, size, han, ^(UIImage * _Nonnull image) {
                kGCD_banner_main(^{
                    CALayer *layer = [weakself kj_setLayerImageContents:image?:han.placeholder];
                    layer.contentsGravity = han.viewContentsGravity?:kCAGravityResize;
                });
            });
        }
    });
}
/// 设置Layer上面的内容，默认充满的填充方式
- (CALayer*)kj_setLayerImageContents:(UIImage*)image{
    CALayer * imageLayer = [CALayer layer];
    imageLayer.bounds = self.bounds;
    imageLayer.position = CGPointMake(self.bounds.size.width*.5, self.bounds.size.height*.5);
    imageLayer.contents = (id)image.CGImage;
    [self.layer addSublayer:imageLayer];
    return imageLayer;
}

#pragma mark - function
/// 播放图片
NS_INLINE UIImage * kBannerPlayImage(NSData * data, CGSize size, id<KJBannerWebImageHandle> _Nullable han){
    if (data == nil) return nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData(CFBridgingRetain(data), nil);
    size_t imageCount = CGImageSourceGetCount(imageSource);
    UIImage *animatedImage;
    if (imageCount <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
        if (han.cropScale) {
            UIImage * scaleImage = kBannerCropImage(animatedImage, size);
            animatedImage = scaleImage;
            if (han.kCropScaleImage) han.kCropScaleImage(animatedImage, scaleImage);
        }
    }else{
        NSMutableArray *scaleImages = [NSMutableArray arrayWithCapacity:imageCount];
        NSMutableArray *originalImages = [NSMutableArray arrayWithCapacity:imageCount];
        NSTimeInterval time = 0;
        for (int i = 0; i<imageCount; i++) {
            CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil);
            UIImage *originalImage = [UIImage imageWithCGImage:cgImage];
            if (han.cropScale) {
                UIImage * scaleImage = kBannerCropImage(originalImage, size);
                originalImage = scaleImage;
                if (han.kCropScaleImage) [originalImages addObject:originalImage];
            }
            [scaleImages addObject:originalImage];
            CGImageRelease(cgImage);
            CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, NULL);
            CFDictionaryRef const gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
            NSNumber *duration = (__bridge id)CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (duration == NULL || [duration doubleValue] == 0) {
                duration = (__bridge id)CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            CFRelease(properties);
            CFRelease(gifProperties);
            time += duration.doubleValue;
        }
        animatedImage = [UIImage animatedImageWithImages:scaleImages duration:time];
        if (han.cropScale && han.kCropScaleImage) {
            UIImage *originalImage = [UIImage animatedImageWithImages:originalImages duration:time];
            han.kCropScaleImage(originalImage, animatedImage);
        }
    }
    CFRelease(imageSource);
    return animatedImage;
}
/// 获取图片
NS_INLINE UIImage * kBannerWebImageSetImage(NSData * data, CGSize size, id<KJBannerWebImageHandle> han){
    UIImage *image = kBannerPlayImage(data, size, han);
    kGCD_banner_main(^{
        if (han.completed) {
            han.completed(kBannerContentType(data), image, data, nil);
        }
    });
    return image;
}
/// 下载图片
NS_INLINE void kBannerWebImageDownloader(NSURL * url, CGSize size, id<KJBannerWebImageHandle> han, void(^imageblock)(UIImage *image)){
    void (^kDownloaderAnalysis)(NSData *__data) = ^(NSData *__data){
        if (__data == nil) return;
        if (imageblock) {
            imageblock(kBannerWebImageSetImage(__data, size, han));
        }
        if (han.cacheDatas) {
            [KJBannerViewCacheManager kj_storeGIFData:__data Key:url.absoluteString];
        }
    };
    KJBannerViewDownloader *downloader = [KJBannerViewDownloader new];
    if (han.progress) {
        [downloader kj_startDownloadImageWithURL:url Progress:^(KJBannerDownloadProgress * downloadProgress) {
            han.progress(downloadProgress);
        } Complete:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (error) {
                if (han.completed) han.completed(KJBannerImageTypeUnknown, nil, nil, error);
            }else{
                kDownloaderAnalysis(data);
            }
        }];
    }else{
        [downloader kj_startDownloadImageWithURL:url Progress:nil Complete:^(NSData * data, NSError * error) {
            if (error) {
                if (han.completed) han.completed(KJBannerImageTypeUnknown, nil, nil, error);
            }else{
                kDownloaderAnalysis(data);
            }
        }];
    }
}

#pragma maek - Associated
- (UIImage *)placeholder{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setPlaceholder:(UIImage *)placeholder{
    objc_setAssociatedObject(self, @selector(placeholder), placeholder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (KJWebImageCompleted)completed{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setCompleted:(KJWebImageCompleted)completed{
    objc_setAssociatedObject(self, @selector(completed), completed, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (KJLoadProgressBlock)progress{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setProgress:(KJLoadProgressBlock)progress{
    objc_setAssociatedObject(self, @selector(progress), progress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (bool)cacheDatas{
    return [objc_getAssociatedObject(self, _cmd) intValue];
}
- (void)setCacheDatas:(bool)cacheDatas{
    objc_setAssociatedObject(self, @selector(cacheDatas), @(cacheDatas), OBJC_ASSOCIATION_ASSIGN);
}
- (bool)cropScale{
    return [objc_getAssociatedObject(self, _cmd) intValue];
}
- (void)setCropScale:(bool)cropScale{
    objc_setAssociatedObject(self, @selector(cropScale), @(cropScale), OBJC_ASSOCIATION_ASSIGN);
}
- (void (^)(UIImage *, UIImage *))kCropScaleImage{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setKCropScaleImage:(void (^)(UIImage *, UIImage *))kCropScaleImage{
    objc_setAssociatedObject(self, @selector(kCropScaleImage), kCropScaleImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
