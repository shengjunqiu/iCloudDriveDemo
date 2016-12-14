//
//  QSJDocument.m
//  iclouddrivedemo
//
//  Created by 邱圣军 on 2016/12/9.
//  Copyright © 2016年 邱圣军. All rights reserved.
//

#import "QSJDocument.h"

@implementation QSJDocument
//重写父类方法

/*
 保存时调用该方法
 typeName：文档文件类型后缀
 outError：错误信息输出
 @return：文档数据
 */
- (id)contentsForType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError{
    if (self.data) {
        return [self.data copy];
    }
    return [NSData data];
}

/*
 读取时调用该方法
 contents：文档数据
 typeName：文档文件类型后缀
 outError：错误信息输出
 return：读取是否成功
 */
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError{
    self.data = [contents copy];
    return true;
}

@end
