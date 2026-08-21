<?php

namespace App\Services;

use Aws\Exception\MultipartUploadException;
use Aws\S3\MultipartUploader;
use Aws\S3\S3Client;
use GuzzleHttp\Psr7\Utils;
use Illuminate\Support\Facades\Cache;

class S3UploadWithProgress
{
    public const PROGRESS_PREFIX = 'upload_progress_';

    public function __construct(
        private S3Client $client,
        private string $bucket,
        private int $partSize = 5 * 1024 * 1024,
    ) {
    }

    /**
     * Unggah file ke S3 memakai multipart upload dan mencatat progres
     * (byte yang sudah terkirim) ke Cache, dapat dipantau via polling.
     *
     * @return string key (folder/filename)
     *
     * @throws MultipartUploadException
     */
    public function upload(
        string $folder,
        string $localPath,
        string $filename,
        int $totalBytes,
        string $token = '',
        ?string $originalName = null,
    ): string {
        $key = trim($folder, '/').'/'.$filename;

        $source = Utils::streamFor(fopen($localPath, 'r'));

        $uploader = new MultipartUploader($this->client, $source, [
            'bucket' => $this->bucket,
            'key' => $key,
            'acl' => 'public-read',
            'part_size' => $this->partSize,
            'before_initiate' => function ($command) use ($originalName) {
                if ($originalName) {
                    $command['ContentDisposition'] = $this->contentDisposition($originalName);
                }
            },
            'before_upload' => function ($command) use ($token, $totalBytes) {
                if (! $token) {
                    return;
                }
                $uploaded = ($command['PartNumber'] - 1) * $this->partSize;
                $this->writeProgress($token, min($uploaded, $totalBytes), $totalBytes);
            },
        ]);

        try {
            $uploader->upload();
        } catch (MultipartUploadException $e) {
            $this->clearProgress($token);
            $this->abortUpload($e);

            throw $e;
        }

        $this->clearProgress($token);

        return $key;
    }

    public function writeProgress(string $token, int $uploaded, int $total): void
    {
        if (! $token) {
            return;
        }

        Cache::put(self::PROGRESS_PREFIX.$token, [
            'uploaded' => $uploaded,
            'total' => $total,
        ], now()->addMinutes(30));
    }

    public function readProgress(string $token): ?array
    {
        return Cache::get(self::PROGRESS_PREFIX.$token);
    }

    public function clearProgress(string $token): void
    {
        if ($token) {
            Cache::forget(self::PROGRESS_PREFIX.$token);
        }
    }

    private function abortUpload(MultipartUploadException $e): void
    {
        try {
            $state = $e->getState();
            $id = $state->getId();

            $this->client->abortMultipartUpload([
                'Bucket' => $id['Bucket'],
                'Key' => $id['Key'],
                'UploadId' => $id['UploadId'],
            ]);
        } catch (\Throwable $ignored) {
            // abaikan bila abort tidak memungkinkan
        }
    }

    private function contentDisposition(string $filename): string
    {
        $sanitized = preg_replace('/["\r\n\x00-\x1f\x7f]/', '', $filename) ?? $filename;

        if ($sanitized === $filename) {
            return 'attachment; filename="'.$sanitized.'"';
        }

        return 'attachment; filename="'.$sanitized.'"; filename*=UTF-8\'\''.rawurlencode($filename);
    }
}
