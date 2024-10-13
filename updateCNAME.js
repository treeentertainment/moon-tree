const fs = require('fs');

// JSON 파일 읽기
const subdomains = JSON.parse(fs.readFileSync('subdomains.json', 'utf8'));

// GitHub 유저 이름 가져오기
const username = process.env.GITHUB_ACTOR; // GitHub Action에서 제공하는 환경 변수

// 해당 유저의 서브도메인 가져오기
const cname = subdomains[username];

if (cname) {
  // CNAME 파일에 서브도메인 쓰기
  fs.writeFileSync('CNAME', cname);
  console.log(`CNAME updated to ${cname}`);
} else {
  // 유저 이름에 대한 서브도메인 정보가 없을 경우 에러 처리
  console.error(`No CNAME found for user: ${username}`);
  process.exit(1); // 에러 발생 시 작업 실패로 종료
}
