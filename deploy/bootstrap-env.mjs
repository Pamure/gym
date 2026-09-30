// Only explicit first-run bootstrap credentials are serialized. Never copy a
// developer .env or inherited AI keys. Base64 keeps arbitrary password characters
// literal through Compose's env-file interpolation (it is NOT encryption).
import { pathToFileURL } from 'node:url';

export function bootstrapEnv(password) {
  if (password.length < 10 || password.length > 128 || /[\r\n\0]/.test(password)) {
    throw new Error('password must be 10-128 characters, without line breaks or NUL');
  }
  return `BOOTSTRAP_USERNAME=mjonir\nBOOTSTRAP_PASSWORD_BASE64=${Buffer.from(password, 'utf8').toString('base64')}\n`;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  let password = '';
  process.stdin.setEncoding('utf8');
  for await (const chunk of process.stdin) password += chunk;
  try {
    process.stdout.write(bootstrapEnv(password));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
