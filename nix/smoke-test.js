const path = require("node:path");
const { Qpdf } = require(path.resolve("dist/index.js"));

function minimalPdf() {
  const objects = [
    "<< /Type /Catalog /Pages 2 0 R >>",
    "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>",
  ];
  let body = "%PDF-1.4\n";
  const offsets = [];
  objects.forEach((object, index) => {
    offsets.push(body.length);
    body += `${index + 1} 0 obj\n${object}\nendobj\n`;
  });
  const xref = body.length;
  body += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (const offset of offsets) {
    body += `${String(offset).padStart(10, "0")} 00000 n \n`;
  }
  body += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n`;
  body += `startxref\n${xref}\n%%EOF\n`;
  return Buffer.from(body, "latin1");
}

async function main() {
  const logger = {
    log: console.log,
    error: (message) => {
      throw new Error(message);
    },
  };
  const qpdf = await Qpdf.open(minimalPdf(), { logger });
  qpdf.check();
  const output = Buffer.from(qpdf.write());
  if (!output.toString("latin1").startsWith("%PDF-")) {
    throw new Error("write() did not produce a PDF");
  }
  const version = qpdf.version();
  if (version !== process.env.EXPECTED_QPDF_VERSION) {
    throw new Error(
      `expected qpdf ${process.env.EXPECTED_QPDF_VERSION}, got ${version}`,
    );
  }
  console.log(`qpdf ${version} wrote ${output.length} bytes`);
}

main();
