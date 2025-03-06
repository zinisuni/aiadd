import { test, expect, Page, Browser, Route, BrowserContext } from '@playwright/test';

test.describe('Queue System Tests', () => {
  test('should show main page when under capacity', async ({ page }: { page: Page }) => {
    await page.goto('/');
    await expect(page.getByText('Hello from test app!')).toBeVisible();
  });

  test('should redirect to waiting page when over capacity', async ({ browser }: { browser: Browser }) => {
    // 동시에 여러 브라우저 컨텍스트를 생성하여 부하 테스트
    const contexts = await Promise.all(
      Array.from({ length: 110 }, () => browser.newContext())
    );

    const pages = await Promise.all(
      contexts.map((context: BrowserContext) => context.newPage())
    );

    try {
      // 모든 페이지에서 동시에 접속 시도
      await Promise.all(
        pages.map((page: Page) => page.goto('/'))
      );

      // 마지막 페이지로 테스트 진행 (대기열로 리다이렉트되어야 함)
      const lastPage = pages[pages.length - 1];

      // 대기 페이지로 리다이렉트 확인
      await expect(lastPage).toHaveURL(/.*waiting.html/);

      // 대기열 정보가 표시되는지 확인
      await expect(lastPage.getByText('대기열에서 기다려주세요')).toBeVisible();
      await expect(lastPage.locator('#queueCount')).not.toHaveText('-');
      await expect(lastPage.locator('#waitTime')).not.toHaveText('-');
    } finally {
      // 정리
      await Promise.all(contexts.map((context: BrowserContext) => context.close()));
    }
  });

  test('should update queue status periodically', async ({ page }: { page: Page }) => {
    await page.goto('/waiting.html');

    // 초기 대기열 상태 확인
    const initialCount = await page.locator('#queueCount').textContent();

    // 5초 대기 후 상태 업데이트 확인
    await page.waitForTimeout(5000);
    const updatedCount = await page.locator('#queueCount').textContent();

    expect(initialCount).not.toBe('-');
    expect(updatedCount).not.toBe('-');
  });

  test('should redirect to main page when queue position is ready', async ({ page }: { page: Page }) => {
    // 대기열 API 응답을 모킹하여 즉시 입장 가능한 상태로 설정
    await page.route('/api/queue/status', async (route: Route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          canProceed: true,
          redirectUrl: '/',
          queueCount: 0,
          estimatedWaitTime: 0,
          progress: 100
        })
      });
    });

    await page.goto('/waiting.html');
    await expect(page).toHaveURL('/');
  });
});