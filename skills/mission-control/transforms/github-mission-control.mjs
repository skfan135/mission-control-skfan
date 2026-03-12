#!/usr/bin/env node

// GitHub Mission Control Transform
// Handles webhook events from GitHub and processes task changes

import crypto from 'crypto';

export default {
  name: 'GitHub Mission Control Transform',
  description: 'Processes task changes from GitHub webhook',
  version: '1.0.0',
  
  // Main transform function
  async transform(context, request) {
    const { headers, body } = request;
    
    // Verify webhook signature
    const signature = headers['x-hub-signature-256'];
    const secret = context.secrets?.webhookSecret || process.env.GITHUB_WEBHOOK_SECRET;
    
    if (signature && secret) {
      const hmac = crypto.createHmac('sha256', secret);
      hmac.update(JSON.stringify(body));
      const expectedSignature = `sha256=${hmac.digest('hex')}`;
      
      if (signature !== expectedSignature) {
        throw new Error('Invalid webhook signature');
      }
    }
    
    // Handle push events
    if (headers['x-github-event'] === 'push') {
      const { ref, repository, commits } = body;
      
      // Check if push is to main/master branch
      if (!ref.endsWith('master') && !ref.endsWith('main')) {
        return { processed: false, message: 'Not a main branch push' };
      }
      
      // Check if tasks.json was modified
      const tasksModified = commits.some(commit => 
        commit.modified?.includes('data/tasks.json') ||
        commit.added?.includes('data/tasks.json')
      );
      
      if (tasksModified) {
        // Get the task changes
        const changes = await getTaskChanges(context, repository, commits);
        
        // Process tasks moved to 'in_progress'
        const inProgressTasks = changes.filter(change => 
          change.new?.status === 'in_progress' && change.old?.status !== 'in_progress'
        );
        
        if (inProgressTasks.length > 0) {
          // Send work orders to the agent
          const workOrders = inProgressTasks.map(task => ({
            type: 'agent_task',
            data: {
              taskId: task.new.id,
              title: task.new.title,
              description: task.new.description,
              subtasks: task.new.subtasks || [],
              dod: task.new.dod
            }
          }));
          
          return {
            processed: true,
            action: 'route_to_agent',
            data: workOrders
          };
        }
      }
    }
    
    return { processed: false };
  }
};

async function getTaskChanges(context, repository, commits) {
  // Implementation would fetch the diff and extract task changes
  // This is a simplified version
  return [];
}