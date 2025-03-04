import cv2
import numpy as np
import pytesseract
import re
import os
from PIL import Image

class CreditCardOCR:
    def __init__(self):
        # Tesseract 설정 (--lang 옵션 제거)
        self.config = r'--oem 3 --psm 6 -c tessedit_char_whitelist=0123456789/.'

    def preprocess_image(self, image):
        """이미지 전처리 함수"""
        # 그레이스케일 변환
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # 노이즈 제거를 위한 가우시안 블러
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        # 명암 대비 향상
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(blurred)

        # 이진화 (Otsu의 방법)
        _, binary = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        # 모폴로지 연산으로 텍스트 영역 강화
        kernel = np.ones((3, 3), np.uint8)
        morph = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)

        return morph

    def extract_card_info(self, image_path):
        """신용카드 정보 추출 함수"""
        # 이미지 파일 존재 확인
        if not os.path.exists(image_path):
            print(f"Error: 이미지 파일을 찾을 수 없습니다: {image_path}")
            return None, None

        # 이미지 로드
        image = cv2.imread(image_path)
        if image is None:
            print(f"Error: 이미지를 로드할 수 없습니다: {image_path}")
            return None, None

        # 이미지 크기 확인 및 조정
        height, width = image.shape[:2]
        if width > 1000:
            scale = 1000 / width
            image = cv2.resize(image, None, fx=scale, fy=scale)

        # 이미지 전처리
        processed_image = self.preprocess_image(image)

        # 디버깅을 위해 전처리된 이미지 저장
        cv2.imwrite('processed_card.jpg', processed_image)

        # 다양한 전처리 방법 시도
        results = []

        # 방법 1: 기본 전처리
        text1 = pytesseract.image_to_string(processed_image, config=self.config)
        results.append(text1)

        # 방법 2: 반전된 이미지
        inverted = cv2.bitwise_not(processed_image)
        text2 = pytesseract.image_to_string(inverted, config=self.config)
        results.append(text2)

        # 방법 3: PIL 이미지로 변환
        pil_image = Image.fromarray(processed_image)
        text3 = pytesseract.image_to_string(pil_image, config=self.config)
        results.append(text3)

        # 모든 결과 텍스트 합치기
        all_text = ' '.join(results)

        # 디버깅을 위해 OCR 결과 출력
        print("OCR 결과:", all_text)

        # 카드 번호 추출 (다양한 패턴 시도)
        card_number_patterns = [
            r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b',  # 1234 5678 9012 3456
            r'\b\d{16}\b',  # 1234567890123456
            r'\b\d{4}[\s-]?\d{6}[\s-]?\d{5}\b'  # 다른 형식의 카드 번호
        ]

        card_number = None
        for pattern in card_number_patterns:
            matches = re.findall(pattern, all_text)
            if matches:
                card_number = matches[0]
                # 공백과 하이픈 제거
                card_number = re.sub(r'[\s-]', '', card_number)
                # 4자리씩 포맷팅
                card_number = ' '.join([card_number[i:i+4] for i in range(0, len(card_number), 4)])
                break

        # 유효기간 추출 (다양한 패턴 시도)
        expiry_patterns = [
            r'\b(0[1-9]|1[0-2])[/\s.-]([0-9]{2}|20[0-9]{2})\b',  # MM/YY 또는 MM/YYYY
            r'\bVALID[\s:]+(?:THRU|UNTIL|TO)[\s:]+(\d{2})[/\s.-](\d{2})\b',  # VALID THRU 02/25
            r'\bEXP(?:IRY|IRES)?[\s:]+(\d{2})[/\s.-](\d{2})\b'  # EXPIRY 02/25
        ]

        expiry_date = None
        for pattern in expiry_patterns:
            matches = re.findall(pattern, all_text, re.IGNORECASE)
            if matches:
                if isinstance(matches[0], tuple):
                    month, year = matches[0]
                    # 연도가 4자리인 경우 뒤의 2자리만 사용
                    if len(year) == 4:
                        year = year[2:]
                    expiry_date = f"{month}/{year}"
                else:
                    expiry_date = matches[0]
                break

        return card_number, expiry_date

def main():
    # 신용카드 OCR 객체 생성
    card_ocr = CreditCardOCR()

    # 이미지 경로 설정
    image_path = 'credit_card_image.jpg'

    # 카드 정보 추출
    card_number, expiry_date = card_ocr.extract_card_info(image_path)

    # 결과 출력
    print("\n===== 신용카드 정보 추출 결과 =====")
    print(f"카드 번호: {card_number if card_number else '인식 실패'}")
    print(f"유효기간: {expiry_date if expiry_date else '인식 실패'}")
    print("==================================")

if __name__ == "__main__":
    main()
