//
//  ViewController.m
//  iclouddrivedemo
//
//  Created by 邱圣军 on 2016/12/8.
//  Copyright © 2016年 邱圣军. All rights reserved.
//

#import "ViewController.h"
#import "QSJDocument.h"

//容器标识
#define QContainerIdentifier @"iCloud.com.sumiapp.iclouddrivedemo"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

//文档标题
@property (weak, nonatomic) IBOutlet UITextField *textField_filePath;
//文档内容
@property (weak, nonatomic) IBOutlet UITextField *textField_fileContent;
//显示云上文档列表
@property (weak, nonatomic) IBOutlet UITableView *documentTableView;
//显示本地文档列表
@property (weak, nonatomic) IBOutlet UITableView *localDocumentTabelView;

//文档文件信息，键为文件名，值为创建日期
@property (strong, nonatomic) NSMutableDictionary *files;
//查询文档对象
@property (strong, nonatomic) NSMetadataQuery *query;
//当前选中文档
@property (strong, nonatomic) QSJDocument *document;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.documentTableView.delegate = self;
    self.documentTableView.dataSource = self;
    self.localDocumentTabelView.delegate = self;
    self.localDocumentTabelView.dataSource = self;
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma mark----------创建本地及云上文档----------
//在沙盒document文件夹中创建txt文件
- (IBAction)initFiles:(id)sender {
    //创建本地文件
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"沙盒路径%@",documentsDirectory);
    NSString *filePath= [documentsDirectory stringByAppendingPathComponent:self.textField_filePath.text];
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    NSString *fileContent = self.textField_fileContent.text;
    NSData *fileData = [fileContent dataUsingEncoding:NSUTF8StringEncoding];
    [fileManager createFileAtPath:filePath contents:fileData attributes:nil];
    self.textField_filePath.text = @"";
    self.textField_fileContent.text = @"";
    
    [self.localDocumentTabelView reloadData];
}

#pragma mark----------私有方法----------
/*
 取得云端存储文件的地址
 fileName 文件名，如果文件名为nil，则重新创建一个URL
 return 文件地址
 */
- (NSURL *)getUbiquityFileURL:(NSString *)fileName{
    //取得云端URL基地址(参数中传入nil则会默认获取第一个容器)，需要一个容器标示
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *url = [manager URLForUbiquityContainerIdentifier:QContainerIdentifier];
    //取得Documents目录
    url = [url URLByAppendingPathComponent:@"Documents"];
    //取得最终地址
    url = [url URLByAppendingPathComponent:fileName];
    return url;
}

//从iCloud上加载所有文档信息
- (void)loadDocuments
{
    if (!self.query) {
        self.query = [[NSMetadataQuery alloc] init];
        self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        //注意查询状态是通过通知的形式告诉监听对象的
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metadataQueryFinish:) name:NSMetadataQueryDidFinishGatheringNotification object:self.query];//数据获取完成通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metadataQueryFinish:) name:NSMetadataQueryDidUpdateNotification object:self.query];//查询更新通知
    }
    //开始查询
    [self.query startQuery];
}

// 查询更新或者数据获取完成的通知调用
- (void)metadataQueryFinish:(NSNotification *)notification
{
    NSLog(@"数据获取成功！");
    NSArray *items = self.query.results;//查询结果集
    self.files = [NSMutableDictionary dictionary];
    //变量结果集，存储文件名称、创建日期
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMetadataItem *item = obj;
        NSString *fileName = [item valueForAttribute:NSMetadataItemFSNameKey];
        NSDate *date = [item valueForAttribute:NSMetadataItemFSContentChangeDateKey];
        NSDateFormatter *dateformate = [[NSDateFormatter alloc]init];
        dateformate.dateFormat = @"YY-MM-dd HH:mm";
        NSString *dateString = [dateformate stringFromDate:date];
        [self.files setObject:dateString forKey:fileName];
    }];
    
    [self.documentTableView reloadData];
}

//取消第一响应者（使输入键盘消失）
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.textField_filePath resignFirstResponder];
    [self.textField_fileContent resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark----------UITableView数据源----------

//tableView行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == self.documentTableView) {
        return self.files.count;
    }else{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [paths objectAtIndex:0];
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *docArr = [manager subpathsOfDirectoryAtPath:docDir error:nil];
        return docArr.count;
    }
}

//cell复用
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //iCloud Drive文件列表
    if (tableView == self.documentTableView) {
        static NSString *tableId = @"tableid";
        UITableViewCell *cell = [self.documentTableView dequeueReusableCellWithIdentifier:tableId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:tableId];
        }
        
        NSArray *fileNames = self.files.allKeys;
        NSString *fileName = fileNames[indexPath.row];
        cell.textLabel.text = fileName;
        cell.detailTextLabel.text = [self.files valueForKey:fileName];
        
        return cell;

    }else{
        //本地文件列表
        UITableViewCell *localCell = [self.localDocumentTabelView dequeueReusableCellWithIdentifier:@"localcellid"];
        if (!localCell) {
            localCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"localcellid"];
        }
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [paths objectAtIndex:0];
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *docArr = [manager subpathsOfDirectoryAtPath:docDir error:nil];
        NSString *cellText = [NSString stringWithFormat:@"%@.txt",[docArr objectAtIndex:indexPath.row]];
        localCell.textLabel.text = cellText;
    
        return localCell;
    }
}

#pragma mark----------UITableView代理方法---------
//点击Cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //iCloud Drive文件列表
    if (tableView == self.documentTableView) {
        [self.documentTableView deselectRowAtIndexPath:indexPath animated:NO];
    }else{
        //本地文件列表
        [self.localDocumentTabelView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark----------TableViewCell左滑动作----------
-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    //本地文件列表
    if (tableView == self.localDocumentTabelView) {
        //删除按钮
        UITableViewRowAction *rowAction1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *docDir = [paths objectAtIndex:0];
            NSFileManager *manager = [NSFileManager defaultManager];
            NSArray *docArr = [manager subpathsOfDirectoryAtPath:docDir error:nil];
            NSString *fileName = [docArr objectAtIndex:indexPath.row];
            NSString *filePath = [NSString stringWithFormat:@"%@/%@",docDir,fileName];
            [manager removeItemAtPath:filePath error:nil];
            
            [self.localDocumentTabelView reloadData];
            
            NSLog(@"文件路径%@",filePath);
            NSLog(@"删除本地文件");
    
        }];
        //备份按钮
        UITableViewRowAction *rowAction2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"备份" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *docDir = [paths objectAtIndex:0];
            NSFileManager *manager = [NSFileManager defaultManager];
            NSArray *docArr = [manager subpathsOfDirectoryAtPath:docDir error:nil];
            NSString *fileName = [docArr objectAtIndex:indexPath.row];
            NSString *fileUrl = [NSString stringWithFormat:@"%@.txt",fileName];
            NSURL *url = [self getUbiquityFileURL:fileUrl];
            
            QSJDocument *document = [[QSJDocument alloc] initWithFileURL:url];
            NSString *dataString = fileName;
            document.data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
            [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"创建文档成功.");
                    self.textField_filePath.text = @"";
                    self.textField_fileContent.text = @"";
                    //从iCloud上加载所有文档信息
                    [self loadDocuments];
                }else{
                    NSLog(@"创建文档失败.");
                }
            }];
            [self.localDocumentTabelView reloadData];
            NSLog(@"备份至iCloud Drive");
        }];
        
        //按钮颜色
        rowAction1.backgroundColor = [UIColor redColor];
        rowAction2.backgroundColor = [UIColor blueColor];
        
        return @[rowAction1,rowAction2];
    }else{
        //iCloud Drive 文件列表
        //删除按钮
        UITableViewRowAction *rowAction1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            
            NSArray *fileNames = self.files.allKeys;
            NSString *fileName = fileNames[indexPath.row];
            
            //创建要删除的文档URL
            NSURL *url = [self getUbiquityFileURL:fileName];
            NSError *error = nil;
            //删除文档文件
            [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
            if (error) {
                NSLog(@"删除文档过程中发生错误，错误信息：%@",error.localizedDescription);
                return;
            }
            //从集合中删除
            [self.files removeObjectForKey:fileName];
            
            NSLog(@"删除iCloud Drive文件");
            
        }];
        
        UITableViewRowAction *rowAction2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"下载" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            
            NSFileManager *manager = [NSFileManager defaultManager];
            NSURL *url = [manager URLForUbiquityContainerIdentifier:nil];
            
            if (url == nil)
            {
                NSLog(@"iCloud未激活");
                return;
            }
            
            NSArray *fileNames = self.files.allKeys;
            NSString *fileName = fileNames[indexPath.row];
            
            NSURL *iCloudUrl = [NSURL URLWithString:fileName relativeToURL:url];
            
            NSLog(@"%@",fileName);
            NSLog(@"%@",iCloudUrl);
            
            //调用下载方法
            if(![self downloadFileIfNotAvailable:iCloudUrl]){
                NSLog(@"下载失败");
            }else{
                NSLog(@"下载成功");
            }
            
        }];
        
        rowAction1.backgroundColor = [UIColor redColor];
        rowAction2.backgroundColor = [UIColor blueColor];
        return @[rowAction1,rowAction2];
    }
    
}

//Apple官方提供的下载方法
- (BOOL)downloadFileIfNotAvailable:(NSURL*)file {
    NSNumber*  isIniCloud = nil;
    if ([file getResourceValue:&isIniCloud forKey:NSURLIsUbiquitousItemKey error:nil]) {
        // If the item is in iCloud, see if it is downloaded.
        if ([isIniCloud boolValue]) {
            NSNumber*  isDownloaded = nil;
            if ([file getResourceValue:&isDownloaded forKey:NSURLUbiquitousItemDownloadingStatusKey error:nil]) {
                if ([isDownloaded boolValue])
                    return YES;
                
                // Download the file.
                NSFileManager*  fm = [NSFileManager defaultManager];
                NSError *downloadError = nil;
                [fm startDownloadingUbiquitousItemAtURL:file error:&downloadError];
                if (downloadError) {
                    NSLog(@"Error occurred starting download: %@", downloadError);
                }
                return NO;
            }
        }
    }
    // Return YES as long as an explicit download was not started.
    return YES;
}

@end
