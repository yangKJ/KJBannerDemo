//
//  KJBannerViewCacheManager+KJBannerGIF.h
//  KJBannerViewDemo
//
//  Created by 杨科军 on 2020/12/9.
//  Copyright © 2020 杨科军. All rights reserved.
//  https://github.com/yangKJ/KJBannerViewDemo
//  动态图缓存相关

#import "KJBannerViewCacheManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface KJBannerViewCacheManager (KJBannerGIF)
/// 动态图本地获取
+ (void)kj_getGIFImageWithKey:(NSString*)key completion:(void(^)(NSData *data))completion;
/// 将动态图写入本地
+ (void)kj_storeGIFData:(NSData*)data Key:(NSString*)key;

@end

NS_ASSUME_NONNULL_END
