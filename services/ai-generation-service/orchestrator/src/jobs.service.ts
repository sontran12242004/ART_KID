import { Injectable, NotFoundException } from '@nestjs/common';

export interface AiJob {
  jobId: string;
  childId: string;
  drawingImageUrl: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  result?: {
    creatureType: string;
    displayName: string;
    cheeringMessage: string;
    suggestedAnimationId: string;
    model3dGlbUrl?: string;
  };
  createdAt: Date;
  completedAt?: Date;
}

@Injectable()
export class JobsService {
  private readonly jobs: Map<string, AiJob> = new Map();

  createJob(childId: string, drawingImageUrl: string): AiJob {
    const jobId = `job_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const job: AiJob = {
      jobId,
      childId,
      drawingImageUrl,
      status: 'queued',
      createdAt: new Date(),
    };
    this.jobs.set(jobId, job);

    // Đẩy job vào hàng đợi Redis / BullMQ cho GPU Inference Worker tiêu thụ
    // this.queue.add('generate-creature', { jobId, drawingImageUrl });

    return job;
  }

  getJob(jobId: string): AiJob {
    const job = this.jobs.get(jobId);
    if (!job) {
      throw new NotFoundException(`Job ${jobId} không tồn tại`);
    }
    return job;
  }

  updateJobResult(jobId: string, result: AiJob['result']): AiJob {
    const job = this.getJob(jobId);
    job.status = 'completed';
    job.result = result;
    job.completedAt = new Date();
    return job;
  }
}
