import cv2
import numpy as np
import pytesseract
import re
import os
from PIL import Image

# Tesseract 경로 설정 (필요한 경우 주석 해제 후 경로 수정)
# pytesseract.pytesseract.tesseract_cmd = r'/usr/local/bin/tesseract'

class CreditCardOCR:
    def __init__(self):
        # Tesseract 설정 (--lang 옵션 제거)
        self.config = r'--oem 3 --psm 6 -c tessedit_char_whitelist=0123456789/. '

    def preprocess_image(self, image):
        """이미지 전처리 함수"""
        # 원본 이미지 저장
        cv2.imwrite('original_card.jpg', image)

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

        # 추가 전처리 방법: 에지 감지
        edges = cv2.Canny(enhanced, 50, 150)
        dilated_edges = cv2.dilate(edges, kernel, iterations=1)

        # 다양한 전처리 이미지 저장
        cv2.imwrite('gray_card.jpg', gray)
        cv2.imwrite('enhanced_card.jpg', enhanced)
        cv2.imwrite('binary_card.jpg', binary)
        cv2.imwrite('morph_card.jpg', morph)
        cv2.imwrite('edges_card.jpg', dilated_edges)

        return morph, binary, dilated_edges, enhanced

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

        # 이미지 전처리 (여러 방법)
        morph, binary, edges, enhanced = self.preprocess_image(image)

        # 다양한 전처리 방법 시도
        results = []

        # 방법 1: 기본 전처리
        text1 = pytesseract.image_to_string(morph, config=self.config)
        results.append(text1)

        # 방법 2: 반전된 이미지
        inverted = cv2.bitwise_not(binary)
        text2 = pytesseract.image_to_string(inverted, config=self.config)
        results.append(text2)

        # 방법 3: 에지 이미지
        text3 = pytesseract.image_to_string(edges, config=self.config)
        results.append(text3)

        # 방법 4: 향상된 이미지
        text4 = pytesseract.image_to_string(enhanced, config=self.config)
        results.append(text4)

        # 방법 5: PIL 이미지로 변환
        pil_image = Image.fromarray(morph)
        text5 = pytesseract.image_to_string(pil_image, config=self.config)
        results.append(text5)

        # 방법 6: 원본 이미지 직접 사용
        text6 = pytesseract.image_to_string(image, config=self.config)
        results.append(text6)

        # 모든 결과 텍스트 합치기
        all_text = ' '.join(results)

        # 디버깅을 위해 OCR 결과 출력
        print("OCR 결과:", all_text)

        # 카드 번호 추출 (다양한 패턴 시도)
        card_number_patterns = [
            r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b',  # 1234 5678 9012 3456
            r'\b\d{16}\b',  # 1234567890123456
            r'\b\d{4}[\s-]?\d{6}[\s-]?\d{5}\b',  # 다른 형식의 카드 번호
            r'\b\d{3,4}[\s-]?\d{3,4}[\s-]?\d{3,4}[\s-]?\d{3,4}\b'  # 더 유연한 패턴
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
            r'\bEXP(?:IRY|IRES)?[\s:]+(\d{2})[/\s.-](\d{2})\b',  # EXPIRY 02/25
            r'\b(0?[1-9]|1[0-2])[/\s.-](\d{2})\b',  # 더 유연한 패턴 (M/YY)
            r'(?:EXP|VALID)(?:\.|\s|:)*(?:DATE)?(?:\.|\s|:)*(\d{2})[\s/.-](\d{2})',  # EXP DATE 02/25
            r'(\d{2})[\s/.-](\d{2})',  # 단순 MM/YY 패턴
            r'(\d{1,2})[\s/.-](\d{2})'  # 매우 유연한 패턴 (한 자리 월도 허용)
        ]

        expiry_date = None
        for pattern in expiry_patterns:
            matches = re.findall(pattern, all_text, re.IGNORECASE)
            if matches:
                if isinstance(matches[0], tuple):
                    month, year = matches[0]
                    # 월이 한 자리인 경우 앞에 0 추가
                    if len(month) == 1:
                        month = '0' + month
                    # 연도가 4자리인 경우 뒤의 2자리만 사용
                    if len(year) == 4:
                        year = year[2:]
                    expiry_date = f"{month}/{year}"
                else:
                    expiry_date = matches[0]
                break

        # 유효기간을 찾지 못한 경우 숫자 패턴을 직접 찾아보기
        if not expiry_date:
            # 모든 숫자 패턴 찾기
            number_patterns = re.findall(r'\b\d{1,2}[/\s.-]\d{2}\b', all_text)
            if number_patterns:
                for pattern in number_patterns:
                    # 카드 번호가 아닌 패턴 중에서 MM/YY 형식과 유사한 것 찾기
                    if '/' in pattern or '-' in pattern or '.' in pattern:
                        parts = re.split(r'[/\s.-]', pattern)
                        if len(parts) == 2:
                            month, year = parts
                            # 월이 1-12 사이인지 확인
                            if month.isdigit() and 1 <= int(month) <= 12:
                                # 월이 한 자리인 경우 앞에 0 추가
                                if len(month) == 1:
                                    month = '0' + month
                                expiry_date = f"{month}/{year}"
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
