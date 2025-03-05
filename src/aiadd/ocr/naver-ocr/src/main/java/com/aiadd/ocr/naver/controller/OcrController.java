package com.aiadd.ocr.naver.controller;

import com.aiadd.ocr.naver.dto.CardInfoDto;
import com.aiadd.ocr.naver.service.NaverOcrService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Controller
@RequiredArgsConstructor
public class OcrController {

    private final NaverOcrService naverOcrService;

    /**
     * 메인 페이지를 표시합니다.
     */
    @GetMapping("/")
    public String index() {
        return "index";
    }

    /**
     * 카드 이미지를 업로드하고 OCR 처리 결과를 반환합니다.
     */
    @PostMapping("/ocr/card")
    @ResponseBody
    public Map<String, Object> processCardImage(@RequestParam("file") MultipartFile file) {
        Map<String, Object> response = new HashMap<>();

        if (file.isEmpty()) {
            response.put("success", false);
            response.put("message", "파일이 비어있습니다.");
            return response;
        }

        try {
            CardInfoDto cardInfo = naverOcrService.processCardImage(file);

            response.put("success", true);
            response.put("cardInfo", cardInfo);

            return response;
        } catch (IOException e) {
            log.error("카드 이미지 처리 중 오류 발생: {}", e.getMessage());

            response.put("success", false);
            response.put("message", "카드 이미지 처리 중 오류가 발생했습니다: " + e.getMessage());

            return response;
        }
    }

    /**
     * 결과 페이지를 표시합니다.
     */
    @GetMapping("/result")
    public String result(@RequestParam(value = "cardNumber", required = false) String cardNumber,
                         @RequestParam(value = "expiryDate", required = false) String expiryDate,
                         @RequestParam(value = "cardHolder", required = false) String cardHolder,
                         @RequestParam(value = "cardType", required = false) String cardType,
                         Model model) {

        model.addAttribute("cardNumber", cardNumber);
        model.addAttribute("expiryDate", expiryDate);
        model.addAttribute("cardHolder", cardHolder);
        model.addAttribute("cardType", cardType);

        return "result";
    }
}