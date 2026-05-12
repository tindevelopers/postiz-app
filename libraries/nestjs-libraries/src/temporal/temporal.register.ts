import {
  Global,
  Injectable,
  Logger,
  Module,
  OnModuleInit,
} from '@nestjs/common';
import { TemporalService } from 'nestjs-temporal-core';
import { Connection } from '@temporalio/client';

const SEARCH_ATTR_SYNC_MS = 8_000;

function withTimeout<T>(promise: Promise<T>, ms: number, label: string): Promise<T> {
  return new Promise((resolve, reject) => {
    const t = setTimeout(
      () => reject(new Error(`${label} timed out after ${ms}ms`)),
      ms
    );
    promise
      .then((v) => {
        clearTimeout(t);
        resolve(v);
      })
      .catch((e) => {
        clearTimeout(t);
        reject(e);
      });
  });
}

@Injectable()
export class TemporalRegister implements OnModuleInit {
  private readonly _logger = new Logger(TemporalRegister.name);

  constructor(private _client: TemporalService) {}

  async onModuleInit(): Promise<void> {
    if (process.env.TEMPORAL_TLS === 'true') {
      return;
    }
    if (process.env.SKIP_TEMPORAL_SEARCH_ATTRIBUTE_SYNC === 'true') {
      this._logger.warn(
        'Skipping Temporal search-attribute sync (SKIP_TEMPORAL_SEARCH_ATTRIBUTE_SYNC=true)'
      );
      return;
    }
    const connection = this._client?.client?.getRawClient()
      ?.connection as Connection | undefined;
    if (!connection) {
      this._logger.warn('Temporal connection unavailable; skipping search-attribute sync');
      return;
    }

    const namespace = process.env.TEMPORAL_NAMESPACE || 'default';

    try {
      const { customAttributes } = await withTimeout(
        connection.operatorService.listSearchAttributes({
          namespace,
        }),
        SEARCH_ATTR_SYNC_MS,
        'listSearchAttributes'
      );

      const neededAttribute = ['organizationId', 'postId'];
      const missingAttributes = neededAttribute.filter(
        (attr) => !customAttributes[attr]
      );

      if (missingAttributes.length > 0) {
        await withTimeout(
          connection.operatorService.addSearchAttributes({
            namespace,
            searchAttributes: missingAttributes.reduce((all, current) => {
              // @ts-ignore
              all[current] = 1;
              return all;
            }, {}),
          }),
          SEARCH_ATTR_SYNC_MS,
          'addSearchAttributes'
        );
      }
    } catch (err) {
      this._logger.warn(
        `Temporal search-attribute sync skipped (API will still run): ${
          err instanceof Error ? err.message : String(err)
        }`
      );
    }
  }
}

@Global()
@Module({
  imports: [],
  controllers: [],
  providers: [TemporalRegister],
  get exports() {
    return this.providers;
  },
})
export class TemporalRegisterMissingSearchAttributesModule {}
