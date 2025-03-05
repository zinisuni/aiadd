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

            // fields 배열 존재 여부 확인
            if (!firstImage.has("fields")) {
                log.error("OCR 결과에 'fields' 필드가 없습니다: {}", firstImage);
                // 전체 응답 구조 로깅
                logJsonStructure(firstImage, "firstImage");
                return CardInfoDto.builder().build();
            }

            JSONArray fields = firstImage.getJSONArray("fields");
            log.debug("필드 수: {}", fields.length());

            // 카드 번호 추출
            String cardNumber = extractCardNumberFromFields(fields);
            log.debug("추출된 카드 번호: {}", cardNumber);

            // 유효기간 추출
            String expiryDate = extractExpiryDateFromFields(fields);
            log.debug("추출된 유효기간: {}", expiryDate);

            // 카드 소유자 이름 추출
            String cardHolder = extractCardHolderFromFields(fields);
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
     * fields 배열에서 카드 번호를 추출합니다.
     */
    private String extractCardNumberFromFields(JSONArray fields) {
        try {
            // 카드 번호 패턴 (4자리 숫자 그룹)
            Pattern cardNumberPattern = Pattern.compile("\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}");

            // 모든 필드의 텍스트를 연결하여 카드 번호 패턴 검색
            StringBuilder allText = new StringBuilder();
            for (int i = 0; i < fields.length(); i++) {
                JSONObject field = fields.getJSONObject(i);
                if (field.has("inferText")) {
                    String text = field.getString("inferText");
                    allText.append(text).append(" ");
                }
            }

            // 전체 텍스트에서 카드 번호 패턴 검색
            Matcher matcher = cardNumberPattern.matcher(allText.toString());
            if (matcher.find()) {
                String cardNumber = matcher.group().replaceAll("[\\s-]", "");

                // 카드 번호 포맷팅 (4자리씩 그룹화)
                StringBuilder formatted = new StringBuilder();
                for (int i = 0; i < cardNumber.length(); i += 4) {
                    if (i > 0) {
                        formatted.append(" ");
                    }
                    formatted.append(cardNumber.substring(i, Math.min(i + 4, cardNumber.length())));
                }
                return formatted.toString();
            }

            // 개별 필드에서 카드 번호 검색
            for (int i = 0; i < fields.length(); i++) {
                JSONObject field = fields.getJSONObject(i);
                if (field.has("inferText")) {
                    String text = field.getString("inferText");
                    // 4자리 숫자 그룹 확인
                    if (text.matches("\\d{4}") && i + 3 < fields.length()) {
                        // 연속된 4개의 필드가 각각 4자리 숫자인지 확인
                        boolean isCardNumber = true;
                        StringBuilder cardNumber = new StringBuilder(text);

                        for (int j = 1; j <= 3; j++) {
                            JSONObject nextField = fields.getJSONObject(i + j);
                            if (nextField.has("inferText") && nextField.getString("inferText").matches("\\d{4}")) {
                                cardNumber.append(" ").append(nextField.getString("inferText"));
                            } else {
                                isCardNumber = false;
                                break;
                            }
                        }

                        if (isCardNumber) {
                            return cardNumber.toString();
                        }
                    }
                }
            }

            log.debug("카드 번호를 찾을 수 없습니다.");
            return null;
        } catch (Exception e) {
            log.error("카드 번호 추출 중 오류 발생: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * fields 배열에서 유효기간을 추출합니다.
     */
    private String extractExpiryDateFromFields(JSONArray fields) {
        try {
            // 유효기간 패턴 (MM/YY 또는 MM/YYYY 형식)
            Pattern expiryPattern = Pattern.compile("(0[1-9]|1[0-2])/([0-9]{2}|[0-9]{4})");
            Pattern validThruPattern = Pattern.compile("VALID\\s+THRU");

            // VALID THRU 텍스트 다음에 오는 필드 확인
            for (int i = 0; i < fields.length(); i++) {
                JSONObject field = fields.getJSONObject(i);
                if (field.has("inferText")) {
                    String text = field.getString("inferText");
                    if (validThruPattern.matcher(text).find() && i + 1 < fields.length()) {
                        // VALID THRU 다음 필드가 유효기간일 가능성이 높음
                        JSONObject nextField = fields.getJSONObject(i + 1);
                        if (nextField.has("inferText")) {
                            String nextText = nextField.getString("inferText");
                            Matcher matcher = expiryPattern.matcher(nextText);
                            if (matcher.find()) {
                                return matcher.group();
                            }
                        }
                    }
                }
            }

            // 모든 필드에서 유효기간 패턴 검색
            for (int i = 0; i < fields.length(); i++) {
                JSONObject field = fields.getJSONObject(i);
                if (field.has("inferText")) {
                    String text = field.getString("inferText");
                    Matcher matcher = expiryPattern.matcher(text);
                    if (matcher.find()) {
                        return matcher.group();
                    }
                }
            }

            log.debug("유효기간을 찾을 수 없습니다.");
            return null;
        } catch (Exception e) {
            log.error("유효기간 추출 중 오류 발생: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * fields 배열에서 카드 소유자 이름을 추출합니다.
     */
    private String extractCardHolderFromFields(JSONArray fields) {
        try {
            // 현재 Naver CLOVA OCR API는 카드 소유자 이름을 직접 제공하지 않습니다.
            // 카드 소유자 이름은 일반적으로 카드 번호 아래에 위치합니다.
            // 하지만 정확한 추출은 어려울 수 있으므로 null을 반환합니다.
            return null;
        } catch (Exception e) {
            log.error("카드 소유자 이름 추출 중 오류 발생: {}", e.getMessage());
            return null;
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