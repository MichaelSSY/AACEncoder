//
//  ViewController.m
//  AAC_Test
//
//  Created by weiyun on 2018/3/26.
//  Copyright © 2018年 孙世玉. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AACEncoder.h"
#import "AACDecoder.h"

@interface ViewController ()<AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic , strong) AACDecoder                *player;
@property (nonatomic , strong) dispatch_queue_t          AudioQueue;
@property (nonatomic , strong) AACEncoder                *aacEncoder;
@property (nonatomic , strong) AVCaptureSession          *session;
@property (nonatomic , strong) AVCaptureConnection       *audioConnection;
@property (nonatomic , strong) UIButton                  *startBtn;
@property (nonatomic , strong) NSFileHandle              *audioFileHandle;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createFileToDocument];
    [self initStartBtn];
}

#pragma mark 创建文件夹句柄
- (void)createFileToDocument{
    NSString *audioFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"abc.aac"];
    // 有就移除掉
    [[NSFileManager defaultManager] removeItemAtPath:audioFile error:nil];
    // 移除之后再创建
    [[NSFileManager defaultManager] createFileAtPath:audioFile contents:nil attributes:nil];
    self.audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:audioFile];
}

#pragma mark - 设置音频
- (void)setupAudioCapture {
    
    self.aacEncoder = [[AACEncoder alloc] init];
    
    self.session = [[AVCaptureSession alloc] init];
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device:%@",error.description);
    }
    
    if ([self.session canAddInput:audioInput]) {
        [self.session addInput:audioInput];
    }

    self.AudioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    
    AVCaptureAudioDataOutput *audioOutput = [AVCaptureAudioDataOutput new];
    [audioOutput setSampleBufferDelegate:self queue:self.AudioQueue];
    
    if ([self.session canAddOutput:audioOutput]) {
        [self.session addOutput:audioOutput];
    }
    
    self.audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

#pragma mark - 实现 AVCaptureOutputDelegate：
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (connection == _audioConnection)
    {
        // 音频
        [self.aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
            if (encodedData) {
                //NSLog(@"Audio data (%lu):%@", (unsigned long)encodedData.length,encodedData.description);
                [self.audioFileHandle writeData:encodedData];
            }else {
                NSLog(@"Error encoding AAC: %@", error);
            }
        }];
    }else{
        // 视频
        
    }
}


- (void)initStartBtn
{
    _startBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _startBtn.frame = CGRectMake(0, 0, 140, 50);
    _startBtn.backgroundColor = [UIColor orangeColor];
    _startBtn.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height - 120);
    [_startBtn addTarget:self action:@selector(startBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_startBtn setTitle:@"Start" forState:UIControlStateNormal];
    [_startBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:_startBtn];
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    playBtn.frame = CGRectMake(0, 0, 140, 50);
    playBtn.backgroundColor = [UIColor orangeColor];
    playBtn.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height - 240);
    [playBtn addTarget:self action:@selector(playBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [playBtn setTitle:@"Play" forState:UIControlStateNormal];
    [playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:playBtn];
    
//    UIButton *play2Btn = [UIButton buttonWithType:UIButtonTypeSystem];
//    play2Btn.frame = CGRectMake(0, 0, 140, 50);
//    play2Btn.backgroundColor = [UIColor orangeColor];
//    play2Btn.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height - 320);
//    [play2Btn addTarget:self action:@selector(play2BtnClicked) forControlEvents:UIControlEventTouchUpInside];
//    [play2Btn setTitle:@"noDecode" forState:UIControlStateNormal];
//    [play2Btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.view addSubview:play2Btn];
}

#pragma mark - 播放
- (void)playBtnClicked
{
    [self decoderPlay];
}
- (void)decoderPlay{
    self.player = [[AACDecoder alloc] init];
    [self.player play];
}

//- (void)play2BtnClicked{
//    [self noDecoderPlay];
//}
//- (void)noDecoderPlay{
//    NSFileManager *manager = [NSFileManager defaultManager];
//    NSURL *url = [[manager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
//    NSURL *path = [url URLByAppendingPathComponent:@"abc.aac"];
//
//    SystemSoundID soundID;
//    //Creates a system sound object.
//    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(path), &soundID);
//    //Registers a callback function that is invoked when a specified system sound finishes playing.
//    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, &playCallback, (__bridge void * _Nullable)(self));
//    //    AudioServicesPlayAlertSound(soundID);
//    AudioServicesPlaySystemSound(soundID);
//}
//void playCallback(SystemSoundID ID, void  * clientData) {
//    ViewController* controller = (__bridge ViewController *)clientData;
//    [controller finish];
//}
//- (void)finish{
//    NSLog(@"播完了");
//}
//

#pragma mark - 录制
- (void)startBtnClicked:(UIButton *)btn
{
    btn.selected = !btn.selected;
    
    if (btn.selected)
    {
        [self startCamera];
        [_startBtn setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else
    {
        [_startBtn setTitle:@"Start" forState:UIControlStateNormal];
        [self stopCarmera];
    }
}

- (void) startCamera
{
    if (_session == nil) {
        [self setupAudioCapture];
        [self.session commitConfiguration];
    }
    [self.session startRunning];
}

- (void) stopCarmera
{
    [_session stopRunning];
}
- (void)dealloc{
    [_audioFileHandle closeFile];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
