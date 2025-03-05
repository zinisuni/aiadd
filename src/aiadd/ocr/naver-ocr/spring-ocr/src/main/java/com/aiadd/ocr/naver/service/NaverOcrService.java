package com.aiadd.ocr.naver.service;

import com.aiadd.ocr.naver.dto.CardInfoDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.IOUtils;
import org.json.JSONArray;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
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

    private static final String TEMP_DIR = "temp-images";

    /**
     * 이미지 파일을 저장하고 OCR 처리를 수행합니다.
     */
    public CardInfoDto processCardImage(MultipartFile file) throws IOException {
        // 임시 디렉토리 생성
        createTempDirectoryIfNotExists();

        // 파일 저장
        String fileName = saveFile(file);
        String filePath = TEMP_DIR + "/" + fileName;

        try {
            // OCR 처리
            String ocrResult = callNaverOcrApi(filePath);

            // 결과 파싱
            return parseCardInfo(ocrResult);
        } finally {
            // 임시 파일 삭제
            deleteFile(filePath);
        }
    }

    /**
     * 임시 디렉토리가 없으면 생성합니다.
     */
    private void createTempDirectoryIfNotExists() throws IOException {
        Path path = Paths.get(TEMP_DIR);
        if (!Files.exists(path)) {
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

        Path targetPath = Paths.get(TEMP_DIR, fileName);
        Files.copy(file.getInputStream(), targetPath);

        return fileName;
    }

    /**
     * 임시 파일을 삭제합니다.
     */
    private void deleteFile(String filePath) {
        try {
            Files.deleteIfExists(Paths.get(filePath));
        } catch (IOException e) {
            log.error("파일 삭제 중 오류 발생: {}", e.getMessage());
        }
    }

    /**
     * 네이버 CLOVA OCR API를 호출합니다.
     */
    private String callNaverOcrApi(String imagePath) throws IOException {
        // 이미지 인코딩
        String imageData = encodeImageToBase64(imagePath);

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

        // API 호출
        conn.getOutputStream().write(requestJson.toString().getBytes("UTF-8"));

        int responseCode = conn.getResponseCode();
        if (responseCode == 200) {
            InputStream is = conn.getInputStream();
            String response = IOUtils.toString(is, "UTF-8");
            is.close();

            // 디버깅을 위해 응답 저장
            saveResponseToFile(response);

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
            JSONObject jsonResponse = new JSONObject(ocrResult);
            JSONArray images = jsonResponse.getJSONArray("images");

            if (images.length() == 0) {
                log.error("OCR 결과에 이미지 정보가 없습니다.");
                return CardInfoDto.builder().build();
            }

            JSONObject firstImage = images.getJSONObject(0);

            // 카드 번호 추출
            String cardNumber = extractCardNumber(firstImage);

            // 유효기간 추출
            String expiryDate = extractExpiryDate(firstImage);

            // 카드 소유자 이름 추출
            String cardHolder = extractCardHolder(firstImage);

            // 카드 타입 추출
            String cardType = determineCardType(cardNumber);

            return CardInfoDto.builder()
                    .cardNumber(cardNumber)
                    .expiryDate(expiryDate)
                    .cardHolder(cardHolder)
                    .cardType(cardType)
                    .build();

        } catch (Exception e) {
            log.error("카드 정보 파싱 중 오류 발생: {}", e.getMessage());
            return CardInfoDto.builder().build();
        }
    }

    /**
     * OCR 결과에서 카드 번호를 추출합니다.
     */
    private String extractCardNumber(JSONObject imageResult) {
        try {
            JSONArray fields = imageResult.getJSONArray("fields");

            StringBuilder cardNumber = new StringBuilder();

            // 카드 번호 필드 찾기
            for (int i = 0; i < fields.length(); i++) {
                JSONObject field = fields.getJSONObject(i);
                String name = field.optString("name", "");

                if (name.equals("card_number") || name.contains("card_num")) {
                    String inferText = field.getString("inferText");
                    // 숫자만 추출
                    inferText = inferText.replaceAll("[^0-9]", "");
                    cardNumber.append(inferText);
                }
            }

            // 카드 번호 포맷팅 (4자리씩 분리)
            String number = cardNumber.toString();
            if (number.length() >= 16) {
                StringBuilder formatted = new StringBuilder();
                for (int i = 0; i < number.length(); i++) {
                    if (i > 0 && i % 4 == 0) {
                        formatted.append(" ");
                    }
                    formatted.append(number.charAt(i));
                }
                return formatted.toString();
            }

            return number;
        } catch (Exception e) {
            log.error("카드 번호 추출 중 오류 발생: {}", e.getMessage());
            return "";
        }
    }

    /**
     * OCR 결과에서 유효기간을 추출합니다.
     */
    private String extractExpiryDate(JSONObject imageResult) {
        try {
            JSONArray fields = imageResult.getJSONArray("fields");

            // 유효기간 필드 찾기
            for (int i = 0; i < fields.length(); i++) {
                JSONObject field = fields.getJSONObject(i);
                String name = field.optString("name", "");

                if (name.equals("valid_date") || name.contains("expiry")) {
                    String inferText = field.getString("inferText");

                    // MM/YY 형식으로 변환
                    Pattern pattern = Pattern.compile("(\\d{2})\\s*[/\\\\.-]?\\s*(\\d{2})");
                    Matcher matcher = pattern.matcher(inferText);

                    if (matcher.find()) {
                        return matcher.group(1) + "/" + matcher.group(2);
                    }

                    // 숫자만 추출하여 MM/YY 형식으로 변환
                    String digits = inferText.replaceAll("[^0-9]", "");
                    if (digits.length() >= 4) {
                        return digits.substring(0, 2) + "/" + digits.substring(2, 4);
                    }

                    return inferText;
                }
            }

            return "";
        } catch (Exception e) {
            log.error("유효기간 추출 중 오류 발생: {}", e.getMessage());
            return "";
        }
    }

    /**
     * OCR 결과에서 카드 소유자 이름을 추출합니다.
     */
    private String extractCardHolder(JSONObject imageResult) {
        try {
            JSONArray fields = imageResult.getJSONArray("fields");

            // 카드 소유자 필드 찾기
            for (int i = 0; i < fields.length(); i++) {
                JSONObject field = fields.getJSONObject(i);
                String name = field.optString("name", "");

                if (name.equals("card_holder") || name.contains("name")) {
                    String inferText = field.getString("inferText");
                    // 대문자로 변환
                    return inferText.toUpperCase();
                }
            }

            return "";
        } catch (Exception e) {
            log.error("카드 소유자 추출 중 오류 발생: {}", e.getMessage());
            return "";
        }
    }

    /**
     * 카드 번호로 카드 타입을 결정합니다.
     */
    private String determineCardType(String cardNumber) {
        if (cardNumber == null || cardNumber.isEmpty()) {
            return "UNKNOWN";
        }

        // 숫자만 추출
        String number = cardNumber.replaceAll("[^0-9]", "");

        if (number.startsWith("4")) {
            return "VISA";
        } else if (number.startsWith("5")) {
            return "MASTERCARD";
        } else if (number.startsWith("3")) {
            return "AMEX";
        } else if (number.startsWith("6")) {
            return "DISCOVER";
        } else {
            return "UNKNOWN";
        }
    }
}