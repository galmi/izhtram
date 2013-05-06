//
//  galmisearchField.h
//  izhtram
//
//  Created by Ильдар on 06.05.13.
//  Copyright (c) 2013 Ильдар. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface galmiSearchField : UITextField<UITextFieldDelegate>

@property (nonatomic) bool gps; //true если не нужно выделять ближайшую остановку
@property (nonatomic) int pointId;
@property (nonatomic) CGRect oldSize;

@end
