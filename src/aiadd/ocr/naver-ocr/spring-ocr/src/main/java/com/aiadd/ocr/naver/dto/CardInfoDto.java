package com.aiadd.ocr.naver.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CardInfoDto {
    private String cardNumber;
    private String expiryDate;
    private String cardHolder;
    private String cardType;
}