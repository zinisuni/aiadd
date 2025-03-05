package com.aiadd.ocr.naver.service;

import com.aiadd.ocr.naver.dto.CardInfoDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.IOUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Base64;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Slf4j
@Service
@RequiredArgsConstructor
public class NaverOcrService {

    @Value("${naver.ocr.api.url}")
    private String apiUrl;

    @Value("${naver.ocr.secret.key}")
    private String secretKey;

    @Value("${app.temp-dir:temp-images}")
    private String tempDir;

    private final Environment environment;

    /**
     * 이미지 파일을 저장하고 OCR 처리를 수행합니다.
     */
    public CardInfoDto processCardImage(MultipartFile file) throws IOException {
        log.info("카드 이미지 처리 시작: {}, 크기: {}", file.getOriginalFilename(), file.getSize());

        // 현재 활성화된 프로필 로깅
        String[] activeProfiles = environment.getActiveProfiles();
        log.info("현재 활성화된 프로필: {}", Arrays.toString(activeProfiles));

        // 임시 디렉토리 생성
        createTempDirectoryIfNotExists();

        // 파일 저장
        String fileName = saveFile(file);
        String filePath = tempDir + "/" + fileName;
        log.debug("임시 파일 저장 경로: {}", filePath);

        try {
            // OCR 처리
            log.info("네이버 CLOVA OCR API 호출 시작");
            String ocrResult = callNaverOcrApi(filePath);
            log.info("네이버 CLOVA OCR API 호출 완료");

            // 결과 파싱
            CardInfoDto cardInfo = parseCardInfo(ocrResult);
            log.info("카드 정보 추출 완료: {}", cardInfo);
            return cardInfo;
        } catch (Exception e) {
            log.error("카드 이미지 처리 중 오류 발생", e);
            throw e;
        } finally {
            // 임시 파일 삭제
            deleteFile(filePath);
        }
    }

    /**
     * 임시 디렉토리가 없으면 생성합니다.
     */
    private void createTempDirectoryIfNotExists() throws IOException {
        Path path = Paths.get(tempDir);
        if (!Files.exists(path)) {
            log.debug("임시 디렉토리 생성: {}", tempDir);
            Files.createDirectories(path);
        }
    }

    /**
     * 파일을 임시 디렉토리에 저장합니다.
     */
    private String saveFile(MultipartFile file) throws IOException {
        String originalFilename = file.getOriginalFilename();
        String extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        String fileName = UUID.randomUUID().toString() + extension;

        Path targetPath = Paths.get(tempDir, fileName);
        Files.copy(file.getInputStream(), targetPath);
        log.debug("파일 저장 완료: {}", targetPath);

        return fileName;
    }

    /**
     * 임시 파일을 삭제합니다.
     */
    private void deleteFile(String filePath) {
        try {
            boolean deleted = Files.deleteIfExists(Paths.get(filePath));
            log.debug("파일 삭제 {}: {}", deleted ? "성공" : "실패", filePath);
        } catch (IOException e) {
            log.error("파일 삭제 중 오류 발생: {}", e.getMessage());
        }
    }

    /**
     * 네이버 CLOVA OCR API를 호출합니다.
     */
    private String callNaverOcrApi(String imagePath) throws IOException {
        log.debug("이미지 경로: {}", imagePath);

        // 이미지 인코딩
        String imageData = encodeImageToBase64(imagePath);
        log.debug("이미지 Base64 인코딩 완료 (길이: {})", imageData.length());

        // API 요청 준비
        URL url = new URL(apiUrl);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setUseCaches(false);
        conn.setDoInput(true);
        conn.setDoOutput(true);
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("X-OCR-SECRET", secretKey);

        // 요청 데이터 생성
        JSONObject requestJson = new JSONObject();
        requestJson.put("version", "V2");
        requestJson.put("requestId", UUID.randomUUID().toString());
        requestJson.put("timestamp", System.currentTimeMillis());

        JSONObject image = new JSONObject();
        image.put("format", imagePath.substring(imagePath.lastIndexOf(".") + 1).toLowerCase());
        image.put("data", imageData);
        image.put("name", "credit-card");

        JSONArray images = new JSONArray();
        images.put(image);

        requestJson.put("images", images);

        String requestBody = requestJson.toString();
        log.debug("API 요청 데이터 생성 완료 (요청 ID: {})", requestJson.getString("requestId"));

        // API 호출
        conn.getOutputStream().write(requestBody.getBytes("UTF-8"));
        log.debug("API 요청 전송 완료");

        int responseCode = conn.getResponseCode();
        log.info("API 응답 코드: {}", responseCode);

        if (responseCode == 200) {
            InputStream is = conn.getInputStream();
            String response = IOUtils.toString(is, "UTF-8");
            is.close();

            // 디버깅을 위해 응답 저장
            saveResponseToFile(response);
            log.debug("API 응답 저장 완료 (ocr_response.json)");

            return response;
        } else {
            InputStream is = conn.getErrorStream();
            String errorResponse = IOUtils.toString(is, "UTF-8");
            is.close();

            log.error("API 호출 실패 (상태 코드: {})", responseCode);
            log.error("응답: {}", errorResponse);

            throw new IOException("API 호출 실패 (상태 코드: " + responseCode + ")");
        }
    }

    /**
     * 이미지를 Base64로 인코딩합니다.
     */
    private String encodeImageToBase64(String imagePath) throws IOException {
        File file = new File(imagePath);
        FileInputStream fis = new FileInputStream(file);
        byte[] bytes = IOUtils.toByteArray(fis);
        fis.close();
        return Base64.getEncoder().encodeToString(bytes);
    }

    /**
     * API 응답을 파일로 저장합니다.
     */
    private void saveResponseToFile(String response) {
        try {
            Path path = Paths.get("ocr_response.json");
            Files.write(path, response.getBytes());
        } catch (IOException e) {
            log.error("응답 저장 중 오류 발생: {}", e.getMessage());
        }
    }

    /**
     * OCR 결과에서 카드 정보를 추출합니다.
     */
    private CardInfoDto parseCardInfo(String ocrResult) {
        try {
            log.debug("OCR 결과 파싱 시작");
            JSONObject jsonResponse = new JSONObject(ocrResult);

            // 응답 상태 확인
            if (jsonResponse.has("errorMessage")) {
                log.error("OCR API 오류: {}", jsonResponse.getString("errorMessage"));
                return CardInfoDto.builder().build();
            }

            if (!jsonResponse.has("images")) {
                log.error("OCR 결과에 'images' 필드가 없습니다: {}", jsonResponse);
                return CardInfoDto.builder().build();
            }

            JSONArray images = jsonResponse.getJSONArray("images");
            log.debug("이미지 수: {}", images.length());

            if (images.length() == 0) {
                log.error("OCR 결과에 이미지 정보가 없습니다.");
                return CardInfoDto.builder().build();
            }

            JSONObject firstImage = images.getJSONObject(0);

            // 필드 존재 여부 확인
            if (!firstImage.has("creditCard")) {
                log.error("OCR 결과에 'creditCard' 필드가 없습니다: {}", firstImage);
                // 전체 응답 구조 로깅
                logJsonStructure(firstImage, "firstImage");
                return CardInfoDto.builder().build();
            }

            JSONObject creditCard = firstImage.getJSONObject("creditCard");
            if (!creditCard.has("result")) {
                log.error("OCR 결과에 'creditCard.result' 필드가 없습니다: {}", creditCard);
                logJsonStructure(creditCard, "creditCard");
                return CardInfoDto.builder().build();
            }

            JSONObject result = creditCard.getJSONObject("result");

            // 카드 번호 추출
            String cardNumber = extractCardNumberFromCreditCard(result);
            log.debug("추출된 카드 번호: {}", cardNumber);

            // 유효기간 추출
            String expiryDate = extractExpiryDateFromCreditCard(result);
            log.debug("추출된 유효기간: {}", expiryDate);

            // 카드 소유자 이름 추출
            String cardHolder = extractCardHolder(firstImage);
            log.debug("추출된 카드 소유자: {}", cardHolder);

            // 카드 타입 추출
            String cardType = determineCardType(cardNumber);
            log.debug("추출된 카드 타입: {}", cardType);

            return CardInfoDto.builder()
                    .cardNumber(cardNumber)
                    .expiryDate(expiryDate)
                    .cardHolder(cardHolder)
                    .cardType(cardType)
                    .build();

        } catch (Exception e) {
            log.error("카드 정보 파싱 중 오류 발생: {}", e.getMessage(), e);
            return CardInfoDto.builder().build();
        }
    }

    /**
     * JSON 객체의 구조를 로깅합니다.
     */
    private void logJsonStructure(JSONObject json, String name) {
        try {
            log.debug("JSON 구조 ({}):", name);
            for (String key : json.keySet()) {
                Object value = json.get(key);
                if (value instanceof JSONObject) {
                    log.debug("  {} (객체)", key);
                } else if (value instanceof JSONArray) {
                    JSONArray array = (JSONArray) value;
                    log.debug("  {} (배열, 길이: {})", key, array.length());
                } else {
                    log.debug("  {} ({}): {}", key, value.getClass().getSimpleName(), value);
                }
            }
        } catch (Exception e) {
            log.error("JSON 구조 로깅 중 오류 발생: {}", e.getMessage());
        }
    }

    /**
     * 신용카드 결과에서 카드 번호를 추출합니다.
     */
    private String extractCardNumberFromCreditCard(JSONObject creditCardResult) {
        try {
            if (creditCardResult.has("number")) {
                JSONObject numberObj = creditCardResult.getJSONObject("number");
                if (numberObj.has("text")) {
                    String cardNumber = numberObj.getString("text");
                    // 숫자만 추출
                    cardNumber = cardNumber.replaceAll("[^0-9]", "");

                    // 4자리씩 그룹화
                    if (cardNumber.length() >= 12) {
                        StringBuilder formatted = new StringBuilder();
                        for (int i = 0; i < cardNumber.length(); i += 4) {
                            if (i > 0) {
                                formatted.append(" ");
                            }
                            formatted.append(cardNumber.substring(i, Math.min(i + 4, cardNumber.length())));
                        }
                        return formatted.toString();
                    }
                    return cardNumber;
                }
            }
            log.warn("카드 번호 필드를 찾을 수 없습니다.");
            return "";
        } catch (JSONException e) {
            log.error("카드 번호 추출 중 오류 발생: {}", e.getMessage());
            return "";
        }
    }

    /**
     * 신용카드 결과에서 유효기간을 추출합니다.
     */
    private String extractExpiryDateFromCreditCard(JSONObject creditCardResult) {
        try {
            if (creditCardResult.has("validThru")) {
                JSONObject validThruObj = creditCardResult.getJSONObject("validThru");
                if (validThruObj.has("text")) {
                    String expiryDate = validThruObj.getString("text");
                    // 이미 MM/YY 형식이면 그대로 반환
                    if (expiryDate.matches("\\d{2}/\\d{2}")) {
                        return expiryDate;
                    }

                    // 숫자만 추출
                    String numbers = expiryDate.replaceAll("[^0-9]", "");
                    if (numbers.length() >= 4) {
                        return numbers.substring(0, 2) + "/" + numbers.substring(2, 4);
                    }
                    return expiryDate;
                }
            }
            log.warn("유효기간 필드를 찾을 수 없습니다.");
            return "";
        } catch (JSONException e) {
            log.error("유효기간 추출 중 오류 발생: {}", e.getMessage());
            return "";
        }
    }

    /**
     * OCR 결과에서 카드 소유자 이름을 추출합니다.
     */
    private String extractCardHolder(JSONObject imageResult) {
        try {
            // 현재 Naver CLOVA OCR API는 카드 소유자 이름을 직접 제공하지 않습니다.
            // 따라서 이 메서드는 빈 문자열을 반환합니다.
            // 향후 API가 업데이트되면 이 메서드를 수정할 수 있습니다.
            log.warn("카드 소유자 이름 필드는 현재 API에서 제공되지 않습니다.");
            return "";
        } catch (JSONException e) {
            log.error("카드 소유자 이름 추출 중 오류 발생: {}", e.getMessage());
            return "";
        }
    }

    /**
     * 카드 번호를 기반으로 카드 타입을 결정합니다.
     */
    private String determineCardType(String cardNumber) {
        if (cardNumber == null || cardNumber.isEmpty()) {
            return "";
        }

        // 숫자만 추출
        String number = cardNumber.replaceAll("[^0-9]", "");

        if (number.isEmpty()) {
            return "";
        }

        // 첫 번째 숫자로 카드 타입 결정
        char firstDigit = number.charAt(0);

        switch (firstDigit) {
            case '3':
                return "AMEX";
            case '4':
                return "VISA";
            case '5':
                return "MASTERCARD";
            case '6':
                return "DISCOVER";
            default:
                return "UNKNOWN";
        }
    }
}