//
//  KJBannerModel.h
//  KJBannerViewDemo
//
//  Created by 杨科军 on 2019/1/12.
//  Copyright © 2019 杨科军. All rights reserved.
//  https://github.com/yangKJ/KJBannerViewDemo

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface KJBannerModel : NSObject
@property (nonatomic,strong) NSString *customImageUrl;
@property (nonatomic,strong) NSString *customTitle;
@property (nonatomic,strong) UIImage *customImage;
//获取当前设备可用内存
+ (double)availableMemory;
//获取当前任务所占用内存
+ (double)usedMemory;

@end

NS_ASSUME_NONNULL_END
