//
//  YUV420PPlayer.m
//  FFMpeg
//
//  Created by JL on 2022/8/8.
//

#import "YUVMacOSPlayer.h"
#include "YUVCore.hpp"

@interface YUVMacOSPlayer ()
{
    YUVCore *_core;
    CVDisplayLinkRef displayLink;
    YUVItem *item;
}

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) CGRect dstRect;

@property (nonatomic, strong) NSImageView *imgView;
@property (nonatomic, strong) NSImage *imgData;

@end

@implementation YUVMacOSPlayer

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        [self _initlize];
    }
    return self;
}

- (void)_initlize
{
    self->_core = new YUVCore;
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor redColor].CGColor;
    
    _imgView = [[NSImageView alloc] initWithFrame:self.bounds];
    _imgView.wantsLayer = YES;
    _imgView.layer.backgroundColor = [NSColor blueColor].CGColor;
    [self addSubview:_imgView];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    NSLog(@"YUVMacOSPlayer drawRect");
}

- (void)dealloc
{
    NSLog(@"YUVMacOSPlayer dealloc");
    delete self->_core;
    CVDisplayLinkRelease(displayLink);
    
}


- (void)setUpYUVItem:(YUVPlayItem *)yuv;
{
    item = new YUVItem;
    item->width = yuv.w;
    item->height = yuv.h;
    item->pixelFormat = (AVPixelFormat)yuv.pixelFormat;
    item->fps = yuv.fps;
    item->fileName = [yuv.fileName cStringUsingEncoding:NSUTF8StringEncoding];
    
    self->_core->setYUVItem(item);
    int w = CGRectGetWidth(self.frame);
    int h = CGRectGetHeight(self.frame);
    
    // 计算rect
    int dx = 0;
    int dy = 0;
    int dw = yuv.w;
    int dh = yuv.h;
    
    //计算目标尺寸
    if (dw > w || dh > h) { //缩放
        if ( dw * h > w * dh) { //视频的宽高比 > 播放器的宽高比
            dh = w * dh / dw;
            dw = w;
        } else {
            dw = h * dw / dh;
            dh = h;
        }
    }
    //居中
    dx = (w - dw ) >> 1;
    dy = (h - dh ) >> 1;
    _dstRect = CGRectMake(dx, dy, dw, dh);
    NSLog(@"视频的矩形区域 :%@",NSStringFromRect(_dstRect));
    _imgView.frame = _dstRect;
    [self setNeedsLayout:YES];
}

static int i = 0;
- (void)drawView
{
    NSLog(@"drawView %d",i++);
    int error = 0;
    char* buffer = self->_core->getImageDataFromOneFrame(&error);
    if (error != 0 || !buffer) {
        dispatch_cancel(self.timer);
        self.timer = nil;
        if (buffer) {
            free(buffer);
        }
        return;
    }
    int width = item->width;
    int height = item->height;

    //转为RGBA32
    //像素总数
    int pixelCount = width * height;
    int pixelTotalBytes = pixelCount * 4;
    char* rgba = (char*)malloc(pixelTotalBytes);
    for(int i=0; i < pixelCount; ++i) {
        rgba[4*i] = buffer[3*i]; //R
        rgba[4*i+1] = buffer[3*i+1];//G
        rgba[4*i+2] = buffer[3*i+2];//B
        rgba[4*i+3] = (char)255; //A 透明度全部改为1
    }
    
    size_t bufferLength = pixelTotalBytes; //宽*高*4(字节) 1个像素占用4个字节
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, bufferLength, NULL);
    size_t bitsPerComponent = 8;//每一个像素的色彩单元(R G B A) 占用的位数 8bit == 1B
    size_t bitsPerPixel = 32;//RGBA = 4*8
    size_t bytesPerRow = 4 * width; //每一行的字节数,一个像素4个字节 一行的像素数==width

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return;
    }

    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,   // data provider
                                    NULL,       // decode
                                    YES,            // should interpolate
                                    renderingIntent);

    uint32_t* pixels = (uint32_t*)malloc(bufferLength);

    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return;
    }
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);
    if(context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }
    if(context) {
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
//        if (_imgData) {
//            free(_imgData.TIFFRepresentation.bytes);
//        }
        _imgData = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeMake(width, height)];
        CGImageRelease(imageRef);
        CGContextRelease(context);
    }

    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);

    if(pixels) {
        free(pixels);
    }
    if (buffer) {
        free(buffer);
        buffer = nil;
    }
    
    if (!_imgData) return;
    [self.imgView setImage:_imgData];
    [self updateLayer];
}


//- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime
//{
//    @autoreleasepool {
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [self drawView];
//        });
//    }
//    return kCVReturnSuccess;
//}

//static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
//                                      const CVTimeStamp* now,
//                                      const CVTimeStamp* outputTime,
//                                      CVOptionFlags flagsIn,
//                                      CVOptionFlags* flagsOut,
//                                      void* displayLinkContext)
//{
//    CVReturn result = [(__bridge YUVMacOSPlayer *)displayLinkContext getFrameForTime:outputTime];
//    return result;
//}

- (void)play
{
    if (!item) {
        return;
    }
//    CGDirectDisplayID   displayID = CGMainDisplayID();
//    CVReturn            error = kCVReturnSuccess;
//    error = CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink);
//    if (error)
//    {
//        NSLog(@"DisplayLink created with error:%d", error);
//        displayLink = NULL;
//    }
//    CVDisplayLinkSetOutputCallback(displayLink, MyDisplayLinkCallback, (__bridge void *)self);
//
//    CVDisplayLinkStart(displayLink);
    if (!self.timer) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
         
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
         
        self.timer = timer;
        // 定时任务调度设置,0秒后启动,每个5秒运行
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW ,0);
        dispatch_source_set_timer(self.timer, time, 1000/30 * NSEC_PER_MSEC, 3 * NSEC_PER_SEC);
        
        __weak typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.timer, ^{
            // 定时任务
            @autoreleasepool {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf drawView];
                });
            }
        });
         
        dispatch_source_set_cancel_handler(self.timer, ^{
            // 定时取消回调
            NSLog(@"source did cancel...");
        });
         
        // 启动定时器
        dispatch_resume(timer);
    }
}

@end
