#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import requests
import json
import base64
import re
from dotenv import load_dotenv
from pathlib import Path

class NaverCardOCR:
    """
    네이버 CLOVA OCR API를 사용하여 신용카드 정보를 추출하는 클래스
    """

    def __init__(self):
        # .env 파일에서 환경 변수 로드
        load_dotenv()

        # API 키 설정
        self.api_url = os.getenv('NAVER_OCR_API_URL')
        self.secret_key = os.getenv('NAVER_OCR_SECRET_KEY')

        # API 키가 설정되어 있는지 확인
        if not self.api_url or not self.secret_key:
            print("Error: NAVER_OCR_API_URL 또는 NAVER_OCR_SECRET_KEY가 설정되지 않았습니다.")
            print("환경 변수를 설정하거나 .env 파일을 생성하세요.")
            sys.exit(1)

    def _encode_image(self, image_path):
        """이미지 파일을 base64로 인코딩"""
        with open(image_path, "rb") as f:
            image_binary = f.read()
            return base64.b64encode(image_binary).decode('utf-8')

    def extract_card_info(self, image_path):
        """신용카드 이미지에서 정보 추출"""
        # 이미지 파일 존재 확인
        if not os.path.exists(image_path):
            print(f"Error: 이미지 파일을 찾을 수 없습니다: {image_path}")
            return None

        # 이미지 인코딩
        image_base64 = self._encode_image(image_path)

        # API 요청 헤더
        headers = {
            'Content-Type': 'application/json',
            'X-OCR-SECRET': self.secret_key
        }

        # API 요청 데이터
        data = {
            'version': 'V2',
            'requestId': 'card-ocr-request',
            'timestamp': 0,
            'images': [
                {
                    'format': 'jpg',
                    'name': 'credit-card',
                    'data': image_base64,
                    # 신용카드 인식에 최적화된 설정
                    'templateIds': ['tpl_credit_card_front']
                }
            ]
        }

        try:
            # API 호출
            response = requests.post(self.api_url, headers=headers, json=data)

            # 응답 확인
            if response.status_code != 200:
                print(f"Error: API 호출 실패 (상태 코드: {response.status_code})")
                print(f"응답: {response.text}")
                return None

            # JSON 응답 파싱
            result = response.json()

            # 디버깅을 위해 전체 응답 저장
            with open('ocr_response.json', 'w', encoding='utf-8') as f:
                json.dump(result, f, ensure_ascii=False, indent=2)

            # 카드 정보 추출
            return self._parse_card_info(result)

        except Exception as e:
            print(f"Error: API 호출 중 오류 발생: {e}")
            return None

    def _parse_card_info(self, ocr_result):
        """OCR 결과에서 카드 번호와 유효기간 추출"""
        try:
            card_info = {
                'card_number': None,
                'expiry_date': None,
                'card_holder': None,
                'card_type': None
            }

            # 이미지 인식 결과 확인
            if 'images' not in ocr_result or not ocr_result['images']:
                print("Error: 인식 결과가 없습니다.")
                return card_info

            # 필드 정보 추출
            fields = ocr_result['images'][0].get('fields', [])

            # 카드 번호 추출
            card_number_parts = []
            for field in fields:
                name = field.get('name', '')
                inferText = field.get('inferText', '')

                # 카드 번호 부분 추출
                if 'card_number' in name:
                    # 숫자만 추출
                    numbers = re.sub(r'[^0-9]', '', inferText)
                    card_number_parts.append(numbers)

                # 유효기간 추출
                elif 'valid_date' in name or 'expiry' in name:
                    # MM/YY 형식으로 변환
                    date_text = re.sub(r'[^0-9/]', '', inferText)
                    # 슬래시가 없는 경우 추가
                    if '/' not in date_text and len(date_text) >= 4:
                        date_text = date_text[:2] + '/' + date_text[2:4]
                    card_info['expiry_date'] = date_text

                # 카드 소유자 이름 추출
                elif 'name' in name:
                    card_info['card_holder'] = inferText

                # 카드 타입 추출
                elif 'card_type' in name:
                    card_info['card_type'] = inferText

            # 카드 번호 조합
            if card_number_parts:
                full_number = ''.join(card_number_parts)
                # 4자리씩 분할
                formatted_number = ' '.join([full_number[i:i+4] for i in range(0, len(full_number), 4)])
                card_info['card_number'] = formatted_number

            return card_info

        except Exception as e:
            print(f"Error: 카드 정보 파싱 중 오류 발생: {e}")
            return {
                'card_number': None,
                'expiry_date': None,
                'card_holder': None,
                'card_type': None
            }

def main():
    # .env 파일 생성 확인
    env_path = Path('.env')
    if not env_path.exists():
        print("환경 변수 설정 파일(.env)이 없습니다. 생성합니다.")
        with open('.env', 'w') as f:
            f.write("# 네이버 CLOVA OCR API 설정\n")
            f.write("NAVER_OCR_API_URL=https://xxxxxxxx.apigw.ntruss.com/custom/v1/xxxx/xxxxxxxx\n")
            f.write("NAVER_OCR_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxx\n")
        print(".env 파일이 생성되었습니다. API URL과 Secret Key를 설정해주세요.")
        return

    # OCR 객체 생성
    ocr = NaverCardOCR()

    # 이미지 경로 설정
    image_path = '../credit_card_image.jpg'

    # 상대 경로가 작동하지 않는 경우를 위한 대체 경로
    if not os.path.exists(image_path):
        image_path = 'src/aiadd/ocr/credit_card_image.jpg'

    # 사용자 입력 이미지 경로
    if len(sys.argv) > 1:
        image_path = sys.argv[1]

    print(f"이미지 경로: {image_path}")

    # 카드 정보 추출
    card_info = ocr.extract_card_info(image_path)

    if card_info:
        print("\n===== 신용카드 정보 추출 결과 =====")
        print(f"카드 번호: {card_info['card_number'] if card_info['card_number'] else '인식 실패'}")
        print(f"유효기간: {card_info['expiry_date'] if card_info['expiry_date'] else '인식 실패'}")
        print(f"카드 소유자: {card_info['card_holder'] if card_info['card_holder'] else '인식 실패'}")
        print(f"카드 타입: {card_info['card_type'] if card_info['card_type'] else '인식 실패'}")
        print("==================================")
    else:
        print("카드 정보 추출에 실패했습니다.")

if __name__ == "__main__":
    main()