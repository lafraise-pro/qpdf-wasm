/*
 * @lafraise/qpdf: a WebAssembly build of libqpdf
 * Copyright © 2025 La Fraise PRO SAS
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License
 * as published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

import qpdf = require("./qpdf.js");

type IQpdfLogger = {
  log: (message: string) => void;
  error: (message: string) => void;
};

type QpdfOptions = { logger?: IQpdfLogger };

class QpdfError extends Error {
  constructor(...args: ConstructorParameters<ErrorConstructor>) {
    super(...args);
    if (Error.captureStackTrace) Error.captureStackTrace(this, QpdfError);
    this.name = "QpdfError";
  }
}

class Qpdf {
  module: qpdf.QpdfModule;
  qpdfData: number;

  static async open(
    file: Buffer | Uint8Array,
    { logger }: QpdfOptions = {},
  ): Promise<Qpdf> {
    const moduleArg = logger
      ? {
          print: (message: string) => logger.log(message),
          printErr: (message: string) => logger.error(message),
        }
      : {};
    const module = await qpdf.default(moduleArg);
    return new Qpdf(module, file);
  }

  private constructor(module: qpdf.QpdfModule, file: Buffer | Uint8Array) {
    this.module = module;
    this.qpdfData = this.module._qpdf_init();
    if (this.qpdfData === 0) throw new QpdfError("Failed to init qpdf.");
    let ptr;
    try {
      ptr = this.module._malloc(file.byteLength + 8);
    } catch (cause) {
      throw new QpdfError("Failed to allocate space for input document.", {
        cause,
      });
    }
    const descriptionPtr = ptr;
    const filePtr = ptr + 8;
    this.module.HEAPU8.set(
      [100, 111, 99, 46, 112, 100, 102, 0],
      descriptionPtr,
    ); // "doc.pdf\0"
    this.module.HEAPU8.set(file, filePtr);
    this.module._qpdf_read_memory(
      this.qpdfData,
      descriptionPtr,
      filePtr,
      BigInt(file.byteLength),
      0,
    );
    this.throwIfError();
    // libqpdf keeps a reference to the pdf file buffer so we must not free it here.
  }

  check(): void {
    try {
      this.module._qpdf_check_pdf(this.qpdfData);
    } catch (cause) {
      throw new QpdfError("Check function did not return normally.", { cause });
    }
    this.throwIfError();
  }

  write(): Uint8Array {
    this.module._qpdf_init_write_memory(this.qpdfData);
    this.throwIfError();
    this.module._qpdf_set_preserve_encryption(this.qpdfData, 0); // Cannot fail.
    this.module._qpdf_write(this.qpdfData);
    this.throwIfError();
    const bufferSize = this.module._qpdf_get_buffer_length(this.qpdfData);
    const bufferPtr = this.module._qpdf_get_buffer(this.qpdfData);
    return this.module.HEAPU8.slice(bufferPtr, bufferPtr + bufferSize);
  }

  version(): string {
    const versionPtr = this.module._qpdf_get_qpdf_version();
    const versionString = this.module.UTF8ToString(versionPtr);
    return versionString;
  }

  private throwIfError() {
    const qpdfError = this.module._qpdf_get_error(this.qpdfData);
    if (qpdfError === 0) return;
    const errorMessagePtr = this.module._qpdf_get_error_full_text(
      this.qpdfData,
      qpdfError,
    );
    const errorMessage = this.module.UTF8ToString(errorMessagePtr);
    throw new QpdfError(errorMessage);
  }
}

export = { Qpdf, QpdfError };
