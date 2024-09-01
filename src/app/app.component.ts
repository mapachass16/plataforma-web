import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NavigationStart, Router, RouterOutlet } from '@angular/router';
import { SidebarComponent } from './modules/admin/components/sidebar/sidebar.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet, SidebarComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss'
})
export class AppComponent {
  title = 'plataforma-web';
  showHead = false;

  constructor(private _router: Router) {
    _router.events.forEach(event => {
      if (event instanceof NavigationStart) {
        this.showHead = event['url'].includes('/admin');
      }
    });
  }
}
