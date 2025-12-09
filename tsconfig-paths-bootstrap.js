const tsConfigPaths = require('tsconfig-paths');
const path = require('path');

const baseUrl = path.resolve(__dirname, 'dist');

tsConfigPaths.register({
  baseUrl,
  paths: {
    '@config/*': ['config/*'],
    '@shared/*': ['shared/*'],
    '@utils/*': ['shared/utils/*'],
    '@sharedTypes/*': ['shared/types/*'],
    '@classes/*': ['shared/classes/*'],
    '@middlewares/*': ['shared/middlewares/*'],
    '@logging/*': ['shared/logging/*'],
    '@auth/*': ['modules/auth/*'],
    '@users/*': ['modules/users/*'],
    '@cars/*': ['modules/cars/*'],
    '@instructors/*': ['modules/instructors/*'],
    '@permissions/*': ['modules/permissions/*'],
    '@drivingClass/*': ['modules/drivingClass/*'],
    '@payments/*': ['modules/payments/*'],
    '@schedule/*': ['modules/schedule/*'],
    '@notifications/*': ['modules/notifications/*']
  },
});
