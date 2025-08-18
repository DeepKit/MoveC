// 导航栏滚动效果
window.addEventListener('scroll', function() {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.background = 'rgba(255, 255, 255, 0.98)';
        navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
    } else {
        navbar.style.background = 'rgba(255, 255, 255, 0.95)';
        navbar.style.boxShadow = 'none';
    }
});

// 平滑滚动
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// 移动端导航菜单切换
const navToggle = document.querySelector('.nav-toggle');
const navMenu = document.querySelector('.nav-menu');

if (navToggle && navMenu) {
    navToggle.addEventListener('click', function() {
        navMenu.classList.toggle('active');
        navToggle.classList.toggle('active');
    });
}

// 滚动动画
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('animate');
        }
    });
}, observerOptions);

// 为所有需要动画的元素添加观察
document.addEventListener('DOMContentLoaded', function() {
    const animateElements = document.querySelectorAll('.pain-item, .feature-card, .testimonial-card, .safety-item');
    animateElements.forEach(el => {
        el.classList.add('scroll-animate');
        observer.observe(el);
    });
});

// 下载功能
function downloadSoftware(type) {
    // 统计下载次数
    if (typeof gtag !== 'undefined') {
        gtag('event', 'download', {
            'event_category': 'software',
            'event_label': type
        });
    }
    
    // 显示下载提示
    showDownloadModal(type);
}

function showDownloadModal(type) {
    const modal = document.createElement('div');
    modal.className = 'download-modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3>🚀 开始下载</h3>
                <button class="modal-close" onclick="closeModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div class="download-info">
                    <div class="download-icon">📥</div>
                    <h4>C盘瘦身神器 v2.0</h4>
                    <p>文件大小: 2.5MB | 系统要求: Windows 7+</p>
                </div>
                <div class="download-links">
                    ${getDownloadLinks(type)}
                </div>
                <div class="download-tips">
                    <h5>💡 下载提示:</h5>
                    <ul>
                        <li>建议以管理员权限运行程序</li>
                        <li>首次使用建议选择"保守模式"</li>
                        <li>清理前建议关闭其他程序</li>
                    </ul>
                </div>
            </div>
        </div>
        <div class="modal-overlay" onclick="closeModal()"></div>
    `;
    
    document.body.appendChild(modal);
    setTimeout(() => modal.classList.add('show'), 10);
}

function getDownloadLinks(type) {
    const links = {
        official: `
            <a href="#" class="download-link primary" onclick="startDownload('official')">
                <span class="link-icon">🚀</span>
                <span class="link-text">官方下载 (推荐)</span>
            </a>
        `,
        github: `
            <a href="#" class="download-link" onclick="startDownload('github')">
                <span class="link-icon">📱</span>
                <span class="link-text">GitHub下载</span>
            </a>
        `,
        backup: `
            <a href="#" class="download-link" onclick="startDownload('backup')">
                <span class="link-icon">💿</span>
                <span class="link-text">网盘下载</span>
            </a>
        `
    };
    
    return links[type] || links.official;
}

function startDownload(source) {
    // 这里应该是实际的下载链接
    const downloadUrls = {
        official: 'https://github.com/your-repo/releases/latest/download/DiskCleanup.exe',
        github: 'https://github.com/your-repo/releases',
        backup: 'https://pan.baidu.com/your-backup-link'
    };
    
    // 显示下载开始提示
    showNotification('下载开始！请查看浏览器下载进度。', 'success');
    
    // 实际下载逻辑
    window.open(downloadUrls[source] || downloadUrls.official, '_blank');
    
    // 关闭模态框
    closeModal();
}

function closeModal() {
    const modal = document.querySelector('.download-modal');
    if (modal) {
        modal.classList.remove('show');
        setTimeout(() => modal.remove(), 300);
    }
}

// 通知系统
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <span class="notification-icon">${getNotificationIcon(type)}</span>
            <span class="notification-message">${message}</span>
        </div>
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => notification.classList.add('show'), 10);
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

function getNotificationIcon(type) {
    const icons = {
        success: '✅',
        error: '❌',
        warning: '⚠️',
        info: 'ℹ️'
    };
    return icons[type] || icons.info;
}

// 统计功能
function trackEvent(action, category = 'general', label = '') {
    if (typeof gtag !== 'undefined') {
        gtag('event', action, {
            'event_category': category,
            'event_label': label
        });
    }
}

// 页面加载完成后的初始化
document.addEventListener('DOMContentLoaded', function() {
    // 添加页面加载动画
    document.body.classList.add('loaded');
    
    // 初始化统计
    trackEvent('page_view', 'navigation', 'homepage');
    
    // 添加点击统计
    document.querySelectorAll('a[href^="#"]').forEach(link => {
        link.addEventListener('click', function() {
            trackEvent('navigation_click', 'internal', this.getAttribute('href'));
        });
    });
    
    // 添加功能卡片点击统计
    document.querySelectorAll('.feature-card').forEach(card => {
        card.addEventListener('click', function() {
            const title = this.querySelector('h3').textContent;
            trackEvent('feature_interest', 'engagement', title);
        });
    });
});

// 性能监控
window.addEventListener('load', function() {
    // 页面加载时间统计
    const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
    trackEvent('page_load_time', 'performance', Math.round(loadTime / 1000) + 's');
});

// 错误监控
window.addEventListener('error', function(e) {
    trackEvent('javascript_error', 'error', e.message);
});

// 添加CSS样式到head
const modalStyles = `
<style>
.download-modal {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 10000;
    opacity: 0;
    visibility: hidden;
    transition: all 0.3s ease;
}

.download-modal.show {
    opacity: 1;
    visibility: visible;
}

.modal-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(5px);
}

.modal-content {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: white;
    border-radius: 20px;
    max-width: 500px;
    width: 90%;
    max-height: 80vh;
    overflow-y: auto;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 30px;
    border-bottom: 1px solid #e0e0e0;
}

.modal-header h3 {
    margin: 0;
    color: #333;
}

.modal-close {
    background: none;
    border: none;
    font-size: 1.5rem;
    cursor: pointer;
    color: #666;
    padding: 0;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.modal-body {
    padding: 30px;
}

.download-info {
    text-align: center;
    margin-bottom: 30px;
}

.download-icon {
    font-size: 3rem;
    margin-bottom: 15px;
}

.download-info h4 {
    margin: 0 0 10px 0;
    color: #333;
}

.download-info p {
    color: #666;
    margin: 0;
}

.download-links {
    margin-bottom: 30px;
}

.download-link {
    display: flex;
    align-items: center;
    gap: 15px;
    padding: 15px 20px;
    border: 2px solid #e0e0e0;
    border-radius: 10px;
    text-decoration: none;
    color: #333;
    transition: all 0.3s ease;
    margin-bottom: 10px;
}

.download-link:hover {
    border-color: #2563eb;
    background: #f8fafc;
}

.download-link.primary {
    background: #2563eb;
    color: white;
    border-color: #2563eb;
}

.download-link.primary:hover {
    background: #1d4ed8;
}

.link-icon {
    font-size: 1.2rem;
}

.download-tips {
    background: #f8fafc;
    padding: 20px;
    border-radius: 10px;
}

.download-tips h5 {
    margin: 0 0 15px 0;
    color: #333;
}

.download-tips ul {
    margin: 0;
    padding-left: 20px;
}

.download-tips li {
    margin-bottom: 8px;
    color: #666;
}

.notification {
    position: fixed;
    top: 20px;
    right: 20px;
    background: white;
    border-radius: 10px;
    padding: 15px 20px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    z-index: 10001;
    transform: translateX(100%);
    transition: transform 0.3s ease;
    max-width: 300px;
}

.notification.show {
    transform: translateX(0);
}

.notification.success {
    border-left: 4px solid #10b981;
}

.notification.error {
    border-left: 4px solid #ef4444;
}

.notification.warning {
    border-left: 4px solid #f59e0b;
}

.notification.info {
    border-left: 4px solid #3b82f6;
}

.notification-content {
    display: flex;
    align-items: center;
    gap: 10px;
}

.notification-icon {
    font-size: 1.2rem;
}

.notification-message {
    color: #333;
    font-weight: 500;
}

@media (max-width: 768px) {
    .modal-content {
        width: 95%;
        margin: 20px;
    }
    
    .modal-body {
        padding: 20px;
    }
    
    .notification {
        right: 10px;
        left: 10px;
        max-width: none;
    }
}
</style>
`;

document.head.insertAdjacentHTML('beforeend', modalStyles);
