const { createApp } = Vue

  createApp({
    data() {
      return {
        password: null,
        visible: false,
        error: null,
        scene: {},
        config: {},
        distance: 0.009,
        subtitle: 'test',
        attempts: 0,
        tindex: 0,
        scenetext: 'test',
        font: {
          options: [
            'test'
          ],
          selected: 'test',
          tabindex: 0,
          open: false,
        },
        scale: 0.2,
        color: {
          options: [
            '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
            '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
            '21', '22', '23', '24', '25', '26', '27', '28', '29', '30',
            '31', '32', '33', '34', '35', '36', '37', '38', '39', '40',
            '41', '42', '43', '44', '45', '46', '47', '48', '49', '50',
            '51', '52', '53', '54', '55', '56', '57', '58', '59', '60',
            '61', '62', '63', '64'
          ],
          selected: '1',
          tabindex: 0,
          open: false,
        },
        backgroundcolor: {
          options: [
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
            '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
            '21', '22', '23', '24', '25', '26', '27', '28', '29', '30',
            '31', '32', '33', '34', '35', '36', '37', '38', '39', '40',
            '41', '42', '43', '44', '45', '46', '47', '48', '49', '50',
            '51', '52', '53', '54', '55', '56', '57', '58', '59', '60',
            '61', '62', '63', '64'
          ],
          selected: '1',
          tabindex: 0,
          open: false,
        }
      }
    },
    mounted() {
        window.addEventListener('message', this.onMessage);
    },
    destroyed() {
        window.removeEventListener('message')
    },
    methods: {
        onMessage(event) {
            if (event.data.type === 'toggle') {
              this.visible = event.data.visible
              this.config = event.data.config
              this.subtitle = event.data.subtitle
              this.scene = event.data.scene

              this.font.options = event.data.config.Fonts
              this.font.selected = event.data.scene.font
              
              this.color.selected = event.data.scene.color
              this.backgroundcolor.selected = event.data.scene.bg

              this.scenetext = event.data.scene.text

              this.tindex = event.data.index
            }

            
        },
        fireEvent(eve, opts = {}) {
          fetch(`https://${GetParentResourceName()}/`+eve, {
            method: 'POST',
            body: JSON.stringify(opts)
          })
        },
        closeView() {
          this.visible = false
          fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST'
          })
        }
    }
  }).mount('#app')