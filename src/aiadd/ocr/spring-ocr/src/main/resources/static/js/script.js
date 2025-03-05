document.addEventListener('DOMContentLoaded', function() {
    const uploadForm = document.getElementById('uploadForm');
    const cardImage = document.getElementById('cardImage');
    const imagePreview = document.getElementById('imagePreview');
    const preview = document.getElementById('preview');
    const submitBtn = document.getElementById('submitBtn');
    const btnText = document.getElementById('btnText');
    const loadingSpinner = document.getElementById('loadingSpinner');
    const resultSection = document.getElementById('resultSection');
    const errorSection = document.getElementById('errorSection');
    const errorMessage = document.getElementById('errorMessage');

    // 카드 정보 결과 요소
    const cardNumberElement = document.getElementById('cardNumber');
    const expiryDateElement = document.getElementById('expiryDate');
    const cardHolderElement = document.getElementById('cardHolder');
    const cardTypeElement = document.getElementById('cardType');

    // 이미지 미리보기
    cardImage.addEventListener('change', function(e) {
        if (e.target.files && e.target.files[0]) {
            const reader = new FileReader();

            reader.onload = function(e) {
                preview.src = e.target.result;
                imagePreview.classList.remove('d-none');
            };

            reader.readAsDataURL(e.target.files[0]);
        } else {
            imagePreview.classList.add('d-none');
        }
    });

    // 폼 제출
    uploadForm.addEventListener('submit', function(e) {
        e.preventDefault();

        // 파일 확인
        if (!cardImage.files || !cardImage.files[0]) {
            showError('이미지 파일을 선택해주세요.');
            return;
        }

        // 로딩 상태 표시
        setLoadingState(true);

        // 결과 및 오류 섹션 초기화
        resultSection.classList.add('d-none');
        errorSection.classList.add('d-none');

        // FormData 생성
        const formData = new FormData();
        formData.append('file', cardImage.files[0]);

        // API 호출
        fetch('/ocr/card', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            setLoadingState(false);

            if (data.success) {
                displayResult(data.cardInfo);
            } else {
                showError(data.message || '카드 정보 추출에 실패했습니다.');
            }
        })
        .catch(error => {
            setLoadingState(false);
            showError('서버 요청 중 오류가 발생했습니다: ' + error.message);
        });
    });

    // 로딩 상태 설정
    function setLoadingState(isLoading) {
        if (isLoading) {
            btnText.textContent = '처리 중...';
            loadingSpinner.classList.remove('d-none');
            submitBtn.disabled = true;
        } else {
            btnText.textContent = '카드 정보 추출하기';
            loadingSpinner.classList.add('d-none');
            submitBtn.disabled = false;
        }
    }

    // 결과 표시
    function displayResult(cardInfo) {
        // 결과 섹션 표시
        resultSection.classList.remove('d-none');

        // 카드 정보 표시
        cardNumberElement.textContent = cardInfo.cardNumber || '추출 실패';
        expiryDateElement.textContent = cardInfo.expiryDate || '추출 실패';
        cardHolderElement.textContent = cardInfo.cardHolder || '추출 실패';
        cardTypeElement.textContent = cardInfo.cardType || '추출 실패';

        // 카드 타입에 따른 스타일 적용
        if (cardInfo.cardType) {
            let badgeClass = 'badge ';

            switch (cardInfo.cardType) {
                case 'VISA':
                    badgeClass += 'bg-primary';
                    break;
                case 'MASTERCARD':
                    badgeClass += 'bg-danger';
                    break;
                case 'AMEX':
                    badgeClass += 'bg-success';
                    break;
                case 'DISCOVER':
                    badgeClass += 'bg-warning text-dark';
                    break;
                default:
                    badgeClass += 'bg-secondary';
            }

            cardTypeElement.innerHTML = `<span class="${badgeClass}">${cardInfo.cardType}</span>`;
        }
    }

    // 오류 표시
    function showError(message) {
        errorSection.classList.remove('d-none');
        errorMessage.textContent = message;
    }
});