//
//  EQStyle.m
//  WallySoundEffect
//
//  Created by 김현준 on 2017. 4. 19..
//  Copyright © 2017년 Wally. All rights reserved.
//

#import "EQStyle.h"

@implementation EQStyle

@synthesize eqParam = _eqParam;

@end

@implementation EQNormal

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(0),@(0),@(0),@(0),@(0),@(0),@(0),@(0),@(0),@(0)];
    }
    return self;
}

@end

@implementation EQCleanSound

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(3),@(2),@(1),@(-2),@(-1),@(-1),@(0),@(1.5),@(3.5),@(4)];
    }
    return self;
}

@end

@implementation EQAcoustic

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(3),@(4),@(-1),@(1.5),@(1.5),@(2.5),@(2),@(3),@(2.5),@(3.5)];
    }
    return self;
}
@end

@implementation EQBallad

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(4),@(2.5),@(1.5),@(2),@(0),@(-1),@(1.5),@(3),@(4),@(4)];
    }
    return self;
}
@end

@implementation EQClassic

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(4),@(3),@(3),@(-5),@(-2),@(2),@(3.5),@(4),@(2.5),@(3.5)];
    }
    return self;
}
@end

@implementation EQDance

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(3),@(4),@(1),@(-2),@(-2),@(0),@(1),@(3),@(3),@(3)];
    }
    return self;
}
@end

@implementation EQJazz

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(3),@(2),@(3),@(-5),@(-4),@(0),@(1.5),@(2.5),@(3.5),@(3)];
    }
    return self;
}
@end

@implementation EQPop

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(-9),@(3),@(4),@(3),@(0),@(2),@(-2),@(2.5),@(4),@(3)];
    }
    return self;
}
@end

@implementation EQHipHop

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(3),@(4),@(1),@(-4),@(2),@(4),@(2),@(2),@(3.5),@(3)];
    }
    return self;
}
@end

@implementation EQRnB

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(3),@(4),@(2),@(-4),@(-2),@(2),@(2.5),@(3),@(3.5),@(5)];
    }
    return self;
}
@end

@implementation EQRock

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(4.5),@(5),@(1),@(1),@(2),@(4),@(4),@(3.5),@(4),@(3)];
    }
    return self;
}
@end

@implementation EQBassBoost

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(4.5),@(5),@(2.5),@(0.5),@(0),@(0),@(0),@(0),@(1),@(1)];
    }
    return self;
}
@end

@implementation EQVocalBoost

- (id)init {
    self = [super init];
    if (self) {
        self.eqParam = @[@(-5),@(-4),@(-1.5),@(3),@(3.5),@(3.5),@(3.5),@(2),@(1.5),@(0)];
    }
    return self;
}
@end
