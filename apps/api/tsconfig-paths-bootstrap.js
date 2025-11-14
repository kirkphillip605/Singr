import { register } from 'tsconfig-paths';
import { pathToFileURL } from 'url';
const tsConfig = await import(pathToFileURL('./tsconfig.json'), { assert: { type: 'json' } });
register({
  baseUrl: './',
  paths: tsConfig.default.compilerOptions.paths
});
