const assert = require('assert');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');
const awaitWriteStream = require('await-stream-ready').write;
const request = require('request');
const rp = require('request-promise-native');
const yaml = require('js-yaml');

const GH_RELEASES = 'https://api.github.com/repos/chiflix/splayerx/releases';

async function get(url) {
  return rp.get({
    url,
    json: true,
    headers: {
      'User-Agent': 'SPlayer Website Builder',
    }
  });
}

async function getLatestPrerelease() {
  const allReleases = await get(GH_RELEASES);
  return allReleases.find(r => r.prerelease);
}

async function hashFile(file, algorithm = 'sha512', encoding = 'base64', options) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash(algorithm);
    hash.on('error', reject).setEncoding(encoding);
    fs.createReadStream(file, Object.assign({}, options, { highWaterMark: 1024 * 1024 }))
      .on('error', reject)
      .on('end', () => {
        hash.end();
        resolve(hash.read());
      })
      .pipe(hash, { end: false });
  });
}


async function downloadAndVerify(release, platform) {
  const ymlName = platform === 'win32' ? 'latest.yml' : 'latest-mac.yml';
  const ymlUrl = release.assets.find(a => a.name === ymlName).browser_download_url;
  const yml = await get(ymlUrl);
  const json = yaml.safeLoad(yml);
  assert(json.version.split('-')[0] === release.name.split('-')[0]);
  const sha512 = json.sha512;
  const fileAsset = release.assets.find(a => a.name.toLowerCase() === json.path.toLowerCase());
  const fileName = fileAsset.name;
  const filePath = path.join(__dirname, fileName);
  await awaitWriteStream(request(fileAsset.browser_download_url).pipe(fs.createWriteStream(filePath)));

  const actualSha512 = await hashFile(filePath);
  assert(actualSha512 === sha512);

  return { fileName, filePath, sha512 };
}

async function getUpdateInfo(release) {
  const updateInfo = {
    name: release.name,
    releaseNotes: release.body,
    createdAt: release.created_at,
    commitHash: release.target_commitish,
    landingPage: 'https://github.com/chiflix/splayerx/releases',
    files: {},
  };
  await Promise.all(['darwin', 'win32'].map((async (platform) => {
    const { fileName, filePath, sha512 } = await downloadAndVerify(release, platform);
    execSync(`gsutil cp ${filePath} gs://splayer-releases/download/${fileName}`, { encoding: 'utf-8' });
    updateInfo.files[platform] = { sha512, url: `https://cdn.splayer.org/download/${fileName}` };
  })));
  return updateInfo;
}

getLatestPrerelease()
  .then(release => getUpdateInfo(release))
  .then((info) => {
    fs.mkdirSync(path.join(__dirname, '../dist/beta'));
    fs.writeFileSync(path.join(__dirname, '../dist/beta', 'latest.json'), JSON.stringify(info));
    process.stdout.write(JSON.stringify(info));
  })
  .catch(ex => process.exit(1));
